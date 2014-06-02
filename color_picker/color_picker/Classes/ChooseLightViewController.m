//
//  ChooseLightViewController.m
//  color_picker
//
//  Created by Robert Diamond on 3/4/12.
//  Copyright (c) 2012 Robert Diamond. All rights reserved.
//

#import "APIHandler.h"
#import "ChooseLightViewController.h"
#import "ColorPickerViewController.h"
#import "ColorPickerView.h"
#import "com_robertdiamondAppDelegate.h"
#import <objc/objc.h>

@interface ChooseLightViewController()

@property (nonatomic) NSTimer *refreshTimer;
@property (nonatomic) NSTimer *touchTimer;
@property (nonatomic) ColorPickerViewController *cpvc;
@property (nonatomic) Light *currentNode;

- (NSString *)templateForColor:(UIColor *)color color2:(UIColor *)color2 andNode:(NSUInteger)node;
- (void)hideSpinner;

@end

@implementation ChooseLightViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.title = @"Choose a Light";
        _lights = [[NSMutableArray alloc] init];
        _cpvc = [[ColorPickerViewController alloc]initWithNibName:nil bundle:nil];
        _cpvc.delegate = self;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    _spinner.hidden = NO;
    
    _refresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(doRefresh:)];
    self.navigationItem.rightBarButtonItem = _refresh;
    [self doRefresh:nil];
}

- (IBAction)doRefresh:(id)sender {
    //NSLog(@"dorefresh enter sender %@", sender);
    // TODO: Handle if the URL open fails
    NSString *host = [[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"];
    if (host == nil) return;
    __block NSString *req = [NSString stringWithFormat:@"http://%@/query", host];
    __block NSURL *url = [NSURL URLWithString:req];
    if (sender != nil) {
        if ([sender class] != [NSTimer class]) {
            _spinner.hidden = NO;
        } else {
            _refreshTimer = nil;
        }
    }
    @synchronized (self) {
        [_refreshTimer invalidate];
        _refreshTimer = nil;
        NSLog(@"cleared timer");
    }
    NSLog(@"url %@", url);
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    __weak ChooseLightViewController *weakSelf = self;
    [[APIHandler sharedAPIHandler] handleRequest:request withCallback:^(NSURLResponse *response, NSError *error, NSData *data) {
        //NSLog(@"got result %@", result);
        ChooseLightViewController *strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf hideSpinner];
            _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:strongSelf selector:@selector(doRefresh:) userInfo:nil repeats:NO];
            if (!error) {
                id JSONData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (!error) {
                    [strongSelf _parseLights:JSONData];
                }
            }
            if (error) {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Problem" message:error.localizedDescription delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:@"Retry", nil];
                [av show];
                NSLog(@"Failed to retrieve or parse query results, %@", error.localizedDescription);
            }
        }
    }];
    //NSLog(@"dorefresh exit");
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"arduino"];
        com_robertdiamondAppDelegate *app = (com_robertdiamondAppDelegate *)[[UIApplication sharedApplication] delegate];
        [app applicationDidBecomeActive:[UIApplication sharedApplication]];
    }
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    @synchronized(self) {
        [_refreshTimer invalidate];
        _refreshTimer = nil;
    }
    _refresh = nil;
}

- (void)hideSpinner {
    [_spinner setHidden:YES];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (YES);
}

- (void)_parseLights:(id)jsonData {
    if (![jsonData isKindOfClass:[NSArray class]]) {
        return;
    }
    NSMutableSet *lightSet = [NSMutableSet setWithArray:_lights];
    for (NSDictionary *lightDict in jsonData) {
        Light *newLight = [Light new];
        newLight.name = lightDict[@"name"];
        newLight.nodeID = lightDict[@"string_address"];
        union {
            NSUInteger color;
            Byte rgb[4];
        } color;
        color.color = strtoul([lightDict[@"color"] UTF8String], nil, 16);
        newLight.color1 = [UIColor colorWithRed:color.rgb[2]/255.0 green:color.rgb[1]/255.0 blue:color.rgb[0]/255.0 alpha:1.0];
        color.color = strtoul([lightDict[@"color2"] UTF8String], nil, 16);
        newLight.color2 = [UIColor colorWithRed:color.rgb[2]/255.0 green:color.rgb[1]/255.0 blue:color.rgb[0]/255.0 alpha:1.0];
        [lightSet addObject:newLight];
    }
    _lights = [[lightSet allObjects] sortedArrayUsingComparator:^NSComparisonResult(Light *obj1, Light *obj2) {
        return [obj1.name compare:obj2.name];
    }];

    [self updateTable];
}

- (void)updateTable {
    if (![NSThread isMainThread]) return;
    _spinner.hidden = YES;
    [self.tableView reloadData];
    if ([self tableView:self.tableView numberOfRowsInSection:0] == 0) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"No Lights" message:@"No lights defined" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [av show];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_lights count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Light *light = [_lights objectAtIndex:indexPath.row];

    UITableViewCell *ret = [tableView_ dequeueReusableCellWithIdentifier:@"lightCell"];
    if (ret == nil) {
        ret = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"lightCell"];
    }
    
    NSDate *lastActive = light.lastActive;
    if ([[NSDate date] timeIntervalSinceDate:lastActive] > 90.0 * 60.0) {
        ret.textLabel.textColor = [UIColor redColor];
        ret.textLabel.text = light.name;
        ret.detailTextLabel.text = [NSString stringWithFormat:@"Last Seen %@", [NSDateFormatter localizedStringFromDate:lastActive dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle]];
    } else {
        ret.textLabel.textColor = [UIColor blackColor];
        ret.textLabel.text = light.name;
        ret.detailTextLabel.text = nil;
    }
    
    ret.imageView.image = [UIImage imageNamed:@"lamp icon"];
    ret.imageView.backgroundColor = light.color1;
    
    
    return ret;
}

- (void)tableView:(UITableView *)tableView_ didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"color: %@", currentColor);
    Light *light = [_lights objectAtIndex:indexPath.row];
    UIColor *currentColor = light.color1;

    _currentNode = light;
    [(ColorPickerView *)_cpvc.view setColor:currentColor];
    [self.navigationController pushViewController:_cpvc animated:YES];
    _cpvc.navigationItem.title = light.name;
}

- (void)colorPickerViewController:(ColorPickerViewController *)colorPicker didSelectColor:(UIColor *)color {
  [self colorPickerViewController:colorPicker didTouchColor:color];
}

- (void)doSetColor:(NSTimer *)treq {
  NSURLRequest *req = [treq userInfo];
  [self backgroundRequest:req];
  @synchronized(self) {
    [treq invalidate];
    _touchTimer = nil;
  }
}

- (NSString *)templateForColor:(UIColor *)color color2:(UIColor *)color2 andNode:(NSUInteger)node_ {
  CGFloat r,g,b,r2,g2,b2;
  const CGFloat *comps = CGColorGetComponents(color.CGColor);
    const CGFloat *comps2 = CGColorGetComponents(color2.CGColor);
//    NSString *nodeStr = @"";
//    if (node_ != 1) {
//        nodeStr = [NSString stringWithFormat:@"%d",node_];
//    }
  r = comps[0]; g = comps[1]; b = comps[2];
    r2 = comps2[0]; g2 = comps2[1]; b2 = comps2[2];
  NSString *host = [[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"];
  NSString *ret = [NSString stringWithFormat:@"http://%@/lights?red=%d&green=%d&blue=%d&red2=%d&green2=%d&blue2=%d&node=%%@",
                   host,(int)(r*255), (int)(g*255), (int)(b*255),(int)(r2*255), (int)(g2*255), (int)(b2*255)];
  return ret;
}
- (void)colorPickerViewController:(ColorPickerViewController *)colorPicker didTouchColor:(UIColor *)color {
  colorPicker.defaultsColor = color;
  [_currentNode setValue:color forKey:@"color"];
  //NSLog(@"setting color %@", color);
  //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    NSString *tmpl = [self templateForColor:color color2:color andNode:colorPicker.node];
  NSString *request = [NSString stringWithFormat:tmpl, _currentNode.nodeID];
 
  NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:request] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
  if (_touchTimer) @synchronized(self) {
      [_touchTimer invalidate];
      _touchTimer = nil;
  }
  _touchTimer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(doSetColor:) userInfo:req repeats:NO];
}

- (void)colorPickerViewControllerRandom:(ColorPickerViewController *)colorPicker {
    NSString *host = [[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"];
    NSString *request = [NSString stringWithFormat:@"http://%@/lights?random=Random&node=%@",host,_currentNode.nodeID];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:request] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
    [self backgroundRequest:req];
}

- (void)colorPickerViewController:(ColorPickerViewController *)colorPicker didSelectValue:(NSUInteger)value {
    [(ColorPickerView *)_cpvc.view setColor:(value == 2) ? _currentNode.color2 : _currentNode.color1];
}

- (void)backgroundRequest:(NSURLRequest *)req {
  if ([NSThread isMainThread]) {
    [self performSelectorInBackground:@selector(backgroundRequest:) withObject:req];
    return;
  }
  //NSLog(@"performing request %@", req);
  NSURLResponse *response = nil;
  NSError *error = nil;
  [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
  if (error) {
    NSLog(@"error: %@", error.localizedDescription);
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [self.tableView reloadData];
}
- (IBAction)allLightsOn:(id)sender {
  UIColor *newcolor = [UIColor colorWithRed:1.0 green:.95 blue:.97 alpha:1.0];
    NSString *tmpl = [self templateForColor:newcolor color2:newcolor andNode:1];
  NSString *request = [NSString stringWithFormat:tmpl, @"all"];
  NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:request] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
    [self backgroundRequest:req];
  for (Light *light in _lights) {
      light.color1 = newcolor;
      light.color2 = newcolor;
  }
  [self.tableView reloadData];
}
- (IBAction)allLightsOff:(id)sender {
  UIColor *newcolor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
  NSString *tmpl = [self templateForColor:newcolor color2:newcolor andNode:1];
  NSString *request = [NSString stringWithFormat:tmpl, @"all"];
  NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:request] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
  [self backgroundRequest:req];
    for (Light *light in _lights) {
        light.color1 = newcolor;
        light.color2 = newcolor;
}
  [self.tableView reloadData];
}

@end

@implementation Light

@end
