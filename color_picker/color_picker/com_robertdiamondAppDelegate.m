//
//  com_robertdiamondAppDelegate.m
//  color_picker
//
//  Created by Robert Diamond on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "com_robertdiamondAppDelegate.h"
#import "TBXML.h"
#import "TBXML+HTTP.h"

@implementation com_robertdiamondAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    clvc = [[[ChooseLightViewController alloc] initWithNibName:@"ChooseLightViewController" bundle:nil] autorelease];
    //self.viewController.delegate = self;]
    self.window.rootViewController = [[[UINavigationController alloc] initWithRootViewController:clvc] autorelease];
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
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:@"diamond.homelinux.com:2525", @"arduino", nil]];
    [clvc doRefresh:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
