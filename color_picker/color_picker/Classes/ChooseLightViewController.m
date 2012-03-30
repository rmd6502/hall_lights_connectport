//
//  ChooseLightViewController.m
//  color_picker
//
//  Created by Robert Diamond on 3/4/12.
//  Copyright (c) 2012 America Online. All rights reserved.
//

#import "ChooseLightViewController.h"
#import "ColorPickerViewController.h"
#import "ColorPickerView.h"
#import "TBXML.h"
#import "TBXML+HTTP.h"
#import <objc/objc.h>

@interface ChooseLightViewController(Private)

- (NSString *)templateForColor:(UIColor *)color;

@end

@implementation ChooseLightViewController
@synthesize tbxml;
@synthesize tableView;
@synthesize spinner;
@synthesize refresh;
@synthesize node;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.title = @"Choose a Light";
        lightColors = [[NSMutableDictionary alloc] init];
        cpvc = [[ColorPickerViewController alloc]initWithNibName:nil bundle:nil];
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
    spinner.hidden = NO;
    
    refresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(doRefresh:)];
    self.navigationItem.rightBarButtonItem = refresh;
    [self doRefresh:nil];
}

- (IBAction)doRefresh:(id)sender {
    //NSLog(@"dorefresh enter sender %@", sender);
    __block NSString *req = [NSString stringWithFormat:@"http://%@/query", [[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"]];
    __block NSURL *url = [NSURL URLWithString:req];
    if (sender != nil) {
        if ([sender class] != [NSTimer class]) {
            spinner.hidden = NO;
        } else {
            refreshTimer = nil;
        }
    }
    @synchronized (self) {
        [refreshTimer invalidate];
        [refreshTimer release];
        refreshTimer = nil;
        NSLog(@"cleared timer");
    }
    NSLog(@"url %@", url);
    [TBXML tbxmlWithURL:url success:^(TBXML *result) {
        //NSLog(@"got result %@", result);
        self.tbxml = result;
        refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(doRefresh:) userInfo:nil repeats:NO] retain];
    } failure:^(TBXML *result, NSError *error) {
        NSLog(@"Failed to retrieve or parse query results, %@", error.localizedDescription);
        refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(doRefresh:) userInfo:nil repeats:NO] retain];
    }]; 
    //NSLog(@"dorefresh exit");
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [refresh release];
    [cpvc release];
    @synchronized(self) {
        [refreshTimer invalidate];
        refreshTimer = nil;
    }
    refresh = nil;
}

- (void)dealloc {
    [tbxml release];
    [refresh release];
    [lightColors release];
    [cpvc release];
    [super dealloc];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (YES);
}

- (void)setTbxml:(TBXML *)tbxml_ {
    CGFloat r,g,b;
    
    [tbxml release];
    tbxml = tbxml_;
    [tbxml retain];
    TBXMLElement *element = nil;
    for (element = [TBXML childElementNamed:@"light" parentElement:tbxml.rootXMLElement]; 
         element != nil; element = element->nextSibling) {
        //NSLog(@"light %@", element);
        NSString *nodeId = [TBXML valueOfAttributeNamed:@"node" forElement:element];
        r = [[TBXML textForElement:[TBXML childElementNamed:@"red" parentElement:element]] floatValue]/255.;
        g = [[TBXML textForElement:[TBXML childElementNamed:@"green" parentElement:element]] floatValue]/255.;
        b = [[TBXML textForElement:[TBXML childElementNamed:@"blue" parentElement:element]] floatValue]/255.;
        UIColor *currentColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
        if ([[node objectForKey:@"node"] isEqualToString:nodeId]) {
            [(ColorPickerView *)cpvc.view setColor:currentColor];
        }
        NSString *lightName = [TBXML textForElement:[TBXML childElementNamed:@"nodeId" parentElement:element]];
        unsigned long lastActive = strtoul([[TBXML textForElement:[TBXML childElementNamed:@"lastActive" parentElement:element]] UTF8String], NULL, 10);
        [lightColors setValue:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                               currentColor, @"color", 
                               nodeId, @"node", 
                               [NSNumber numberWithLong:lastActive], @"lastActive",
                               nil] 
                       forKey:lightName];
    }
    
    [self performSelectorOnMainThread:@selector(updateTable) withObject:self waitUntilDone:NO];
}

- (void)updateTable {
    if (![NSThread isMainThread]) return;
    spinner.hidden = YES;
    [tableView reloadData];
    if ([self tableView:tableView numberOfRowsInSection:0] == 0) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"No Lights" message:@"No lights defined" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [av show];
        [av release];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [lightColors count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *lights = [[lightColors allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSString *)obj1 compare:(NSString *)obj2];
    } ];
    NSString *lightName = [lights objectAtIndex:indexPath.row];
    
    UITableViewCell *ret = [tableView_ dequeueReusableCellWithIdentifier:@"lightCell"];
    if (ret == nil) {
        ret = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"lightCell"];
    }
    
    long lastActive = [[[lightColors objectForKey:lightName] objectForKey:@"lastActive"] longValue];
    time_t now = time(NULL);
    time_t local = mktime(localtime(&now));
    if (lastActive > 0 && local - lastActive > 90) {
        ret.textLabel.textColor = [UIColor redColor];
        ret.textLabel.text = lightName;
        ret.detailTextLabel.text = [NSString stringWithFormat:@"Last Seen %@", [NSDateFormatter 
                                    localizedStringFromDate:[NSDate 
                                                             dateWithTimeIntervalSince1970:lastActive] 
                                    dateStyle:NSDateFormatterShortStyle 
                                    timeStyle:NSDateFormatterMediumStyle]];
    } else {
        ret.textLabel.textColor = [UIColor blackColor];
        ret.textLabel.text = lightName;
        ret.detailTextLabel.text = nil;
    }
    
    ret.imageView.image = [UIImage imageNamed:@"lamp icon"];
    ret.imageView.backgroundColor = [[lightColors objectForKey:lightName] objectForKey:@"color"];
    
    
    return ret;
}

- (void)tableView:(UITableView *)tableView_ didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"color: %@", currentColor);
    NSString *lightName = [tableView_ cellForRowAtIndexPath:indexPath].textLabel.text;
    self.node = (NSMutableDictionary *)[lightColors objectForKey:lightName];
    UIColor *currentColor = [node valueForKey:@"color"];

    cpvc.delegate = self;
    [(ColorPickerView *)cpvc.view setColor:currentColor];
    [self.navigationController pushViewController:cpvc animated:YES];
    cpvc.navigationItem.title = lightName;
}

- (void)colorPickerViewController:(ColorPickerViewController *)colorPicker didSelectColor:(UIColor *)color {
  [self colorPickerViewController:colorPicker didTouchColor:color];
}

- (void)doSetColor:(NSTimer *)treq {
  NSURLRequest *req = [treq userInfo];
  [self backgroundRequest:req];
  @synchronized(self) {
    [treq invalidate];
    touchTimer = nil;
  }
}

- (NSString *)templateForColor:(UIColor *)color {
  CGFloat r,g,b;
  const CGFloat *comps = CGColorGetComponents(color.CGColor);
  r = comps[0]; g = comps[1]; b = comps[2];
  NSString *host = [[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"];
  NSString *ret = [NSString stringWithFormat:@"http://%@/lights?red=%d&green=%d&blue=%d&node=%%@",
                   host,(int)(r*255), (int)(g*255), (int)(b*255)];
  return ret;
}
- (void)colorPickerViewController:(ColorPickerViewController *)colorPicker didTouchColor:(UIColor *)color {
  colorPicker.defaultsColor = color;
  [node setValue:color forKey:@"color"];
  NSLog(@"setting color %@", color);
  //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
  NSString *tmpl = [self templateForColor:color];
  NSString *request = [NSString stringWithFormat:tmpl, [node objectForKey:@"node"]];
 
  NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:request] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
  if (touchTimer) @synchronized(self) {
      [touchTimer invalidate];
      touchTimer = nil;
  }
  touchTimer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(doSetColor:) userInfo:req repeats:NO];
}

- (void)colorPickerViewControllerRandom:(ColorPickerViewController *)colorPicker {
    NSString *host = [[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"];
    NSString *request = [NSString stringWithFormat:@"http://%@/lights?random=Random&node=%@",host, 
                         [node objectForKey:@"node"]];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:request] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
    [self backgroundRequest:req];
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
  [tableView reloadData];
}
- (IBAction)allLightsOn:(id)sender {
  UIColor *newcolor = [UIColor colorWithRed:1.0 green:.95 blue:.97 alpha:1.0];
  NSString *tmpl = [self templateForColor:newcolor];
  for (NSString *key in [lightColors allKeys]) {
    NSMutableDictionary *nodeDict = [lightColors objectForKey:key];
    NSString *nodeName = [nodeDict objectForKey:@"node"];
    [nodeDict setObject:newcolor forKey:@"color"];
    NSString *request = [NSString stringWithFormat:tmpl, nodeName];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:request] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
    [self backgroundRequest:req];
  }
  [tableView reloadData];
}
- (IBAction)allLightsOff:(id)sender {
  UIColor *newcolor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
  NSString *tmpl = [self templateForColor:newcolor];
  
  for (NSString *key in [lightColors allKeys]) {
    NSMutableDictionary *nodeDict = [lightColors objectForKey:key];
    [nodeDict setObject:newcolor forKey:@"color"];
    NSString *nodeName = [nodeDict objectForKey:@"node"];
    NSString *request = [NSString stringWithFormat:tmpl, nodeName];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:request] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
    [self backgroundRequest:req];
  }
  [tableView reloadData];
}

@end
