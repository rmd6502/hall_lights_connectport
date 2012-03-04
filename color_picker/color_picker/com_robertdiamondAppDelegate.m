//
//  com_robertdiamondAppDelegate.m
//  color_picker
//
//  Created by Robert Diamond on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "com_robertdiamondAppDelegate.h"

@interface com_robertdiamondAppDelegate()
- (void)loadNodes:(NSString *)req;
- (void)loadFinished;
@end

@implementation com_robertdiamondAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (void)dealloc
{
    [nodeList release];
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    nodeList = [NSMutableArray array];
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    self.viewController = [[[ColorPickerViewController alloc] initWithNibName:@"ColorPickerViewController" bundle:nil] autorelease];
    self.viewController.delegate = self;
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:@"192.168.0.110", @"arduino", nil]];
    NSString *req = [NSString stringWithFormat:@"http://%@/lights/query", [[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"]];
    [self performSelectorInBackground:@selector(loadNodes:) withObject:req];
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
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)colorPickerViewController:(ColorPickerViewController *)colorPicker didSelectColor:(UIColor *)color {
    CGFloat r,g,b;
    const CGFloat *comps = CGColorGetComponents(color.CGColor);
    r = comps[0]; g = comps[1]; b = comps[2];
    //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    NSString *host = [[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"];
    NSString *request = [NSString stringWithFormat:@"http://%@/lights?red=%d&green=%d&blue=%d",host,(int)(r*255), (int)(g*255), (int)(b*255)];
    NSURLResponse *response = nil;
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:request] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
    [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:nil];
}

- (void)colorPickerViewControllerRandom:(ColorPickerViewController *)colorPicker {
    NSString *host = [[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"];
    NSString *request = [NSString stringWithFormat:@"http://%@?random=Random",host];
    NSURLResponse *response = nil;
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:request] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
    [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:nil];
}

- (void)loadNodes:(NSString *)reqString {
    NSURLResponse *resp = nil;
    NSError * error = nil;
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:reqString]];
    nodes = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&error];
    
    if (error) {
        NSLog(@"Failed to load %@, error %@", reqString, error.localizedDescription);
        nodes = nil;
    } else {
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:nodes];
        [parser setDelegate:self];
        [parser parse];
    }
    
    [self performSelectorOnMainThread:@selector(loadFinished) withObject:nil waitUntilDone:NO];
}

- (void)loadFinished {
    
}
@end
