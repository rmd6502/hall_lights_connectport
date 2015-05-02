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
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"].length == 0) {
        [ConnectportDiscovery setDelegate:self];
        [ConnectportDiscovery findDigis];
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
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Discovery" message:@"No Connectports Found" delegate:clvc cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [av show];
            clvc.spinner.hidden = YES;
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_global_queue(0, 0), ^{
            endBlock();
        });
    };

    NSString *request = userInfo[@"request"];
    if ([request isEqualToString:@"lights"]) {
        __weak typeof(clvc) weakClvc = clvc;
        clvc.didRefresh = ^(NSDictionary *lights, NSError *error) {
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
