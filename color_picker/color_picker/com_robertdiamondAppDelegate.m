//
//  com_robertdiamondAppDelegate.m
//  color_picker
//
//  Created by Robert Diamond on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import <arpa/inet.h>
#import "com_robertdiamondAppDelegate.h"
#import "TBXML.h"
#import "TBXML+HTTP.h"
#import "ConnectportDiscovery.h"
#import "ADDPPacket.h"

@interface com_robertdiamondAppDelegate ()

@property (nonatomic,strong) UIAlertController *displayedAlert;

@end

@implementation com_robertdiamondAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    clvc = [[ChooseLightViewController alloc] initWithNibName:@"ChooseLightViewController" bundle:nil];
    //self.viewController.delegate = self;]
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:clvc];
    [self.window makeKeyAndVisible];
    
    //[clvc doRefresh:nil];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.displayedAlert dismissViewControllerAnimated:NO completion:^{
        self.displayedAlert = nil;
    }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"].length == 0) {
        [ConnectportDiscovery setDelegate:self];
        //[ConnectportDiscovery findDigis];
    } 
}

- (void)foundConnectports:(ADDPPacket *)packet orError:(NSError *)error {
    if (packet) {
        struct in_addr ina;
        ina.s_addr = packet.ip;
        NSString *ip = [NSString stringWithUTF8String:inet_ntoa(ina)];
        NSLog(@"address: %@", ip);
        if ([[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"].length == 0) {
            [[NSUserDefaults standardUserDefaults] setObject:ip forKey:@"arduino"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        [clvc doRefresh:nil];
    } else {
        if ([[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"].length == 0) {
            UIApplicationState state = [UIApplication sharedApplication].applicationState;
            if (state == UIApplicationStateActive) {
                self.displayedAlert = [UIAlertController alertControllerWithTitle:@"Discovery" message:@"No Connectports Found" preferredStyle:UIAlertControllerStyleAlert];
                [self.displayedAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    self.displayedAlert = nil;
                }]];
                [self.window.rootViewController presentViewController:self.displayedAlert animated:YES completion:nil];
                clvc.spinner.hidden = YES;
            }
            if (clvc.didRefresh) {
                clvc.didRefresh(nil, [NSError errorWithDomain:@"digi" code:-2222 userInfo:@{NSLocalizedDescriptionKey: @"No Connectports Found"}]);
                clvc.didRefresh = nil;
            }
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

#pragma mark - watchkit
- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))wkreply
{
    __block UIBackgroundTaskIdentifier identifier = UIBackgroundTaskInvalid;
    void (^endBlock)() = ^{
        if (identifier != UIBackgroundTaskInvalid) {
            [application endBackgroundTask:identifier];
        }
        identifier = UIBackgroundTaskInvalid;
    };

    identifier = [application beginBackgroundTaskWithExpirationHandler:endBlock];

    // Wacky but the block will capture the outer reply inside but then later we can still simply call reply - Thanks Dave D!
    void (^reply)(NSDictionary *) = ^(NSDictionary *replyInfo){
        wkreply(replyInfo);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC), dispatch_get_global_queue(0, 0), ^{
            endBlock();
        });
    };

    NSString *request = userInfo[@"request"];
    NSLog(@"Got request %@", request);
    if ([request isEqualToString:@"lights"]) {
        [ConnectportDiscovery setDelegate:self];
        if (clvc == nil) {
            NSLog(@"creating clvc for request");
            [ConnectportDiscovery setDelegate:self];
            clvc = [[ChooseLightViewController alloc] initWithNibName:@"ChooseLightViewController" bundle:nil];
        }
        __weak typeof(clvc) weakClvc = clvc;
        clvc.didRefresh = ^(NSDictionary *lights, NSError *error) {
            NSLog(@"Lights %@ error %@", lights, error);
            if (lights == nil && error == nil) {
                error = [NSError errorWithDomain:@"lights" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"No lights"}];
            }
            if (reply) {
                if (lights) {
                    reply(@{@"lights": lights});
                } else {
                    reply(@{@"error": error});
                }
            }
            weakClvc.didRefresh = nil;
        };
        [clvc doRefresh:nil];
    } else if ([request isEqualToString:@"color"]) {
        UIColor *color = [UIColor colorWithRed:[userInfo[@"red"] doubleValue] green:[userInfo[@"green"] doubleValue] blue:[userInfo[@"blue"] doubleValue] alpha:1.0];
        [clvc node:userInfo[@"node"] didTouchColor:color];
        reply(@{@"response": @"color changed", @"node": userInfo[@"node"] });
    } else {
        reply(@{@"error": @"unknown request"});
    }
}

@end
