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
    refreshTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(doRefresh:) userInfo:nil repeats:YES];
}

- (IBAction)doRefresh:(id)sender {
    __block NSString *req = [NSString stringWithFormat:@"http://%@/query", [[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"]];
    __block NSURL *url = [NSURL URLWithString:req];
    [TBXML tbxmlWithURL:url success:^(TBXML *result) {
        NSLog(@"got result %@", result);
        self.tbxml = result;
    } failure:^(TBXML *result, NSError *error) {
        NSLog(@"Failed to retrieve or parse query results, %@", error.localizedDescription);
    }]; 
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [refresh release];
    [cpvc release];
    [refreshTimer invalidate];
    [refreshTimer release];
    refreshTimer = nil;
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)setTbxml:(TBXML *)tbxml_ {
    CGFloat r,g,b;
    
    [tbxml release];
    tbxml = tbxml_;
    [tbxml retain];
    TBXMLElement *element = nil;
    for (element = [TBXML childElementNamed:@"light" parentElement:tbxml.rootXMLElement]; 
         element != nil; element = element->nextSibling) {
        NSString *nodeId = [TBXML valueOfAttributeNamed:@"node" forElement:element];
        r = [[TBXML textForElement:[TBXML childElementNamed:@"red" parentElement:element]] floatValue]/255.;
        g = [[TBXML textForElement:[TBXML childElementNamed:@"green" parentElement:element]] floatValue]/255.;
        b = [[TBXML textForElement:[TBXML childElementNamed:@"blue" parentElement:element]] floatValue]/255.;
        UIColor *currentColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
        if ([[node objectForKey:@"node"] isEqualToString:nodeId]) {
            [(ColorPickerView *)cpvc.view setColor:currentColor];
        }
        NSString *lightName = [TBXML textForElement:[TBXML childElementNamed:@"nodeId" parentElement:element]];
        [lightColors setValue:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                               currentColor, @"color", 
                               nodeId, @"node", 
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
        ret = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"lightCell"];
    }
    
    ret.textLabel.text = lightName;
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
}

- (void)doSetColor:(NSTimer *)treq {
    NSURLResponse *response = nil;
    NSURLRequest *req = [treq userInfo];
    [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:nil];
    [treq invalidate];
    touchTimer = nil;
}
- (void)colorPickerViewController:(ColorPickerViewController *)colorPicker didTouchColor:(UIColor *)color {
    CGFloat r,g,b;
    colorPicker.defaultsColor = color;
    [node setValue:color forKey:@"color"];
    const CGFloat *comps = CGColorGetComponents(color.CGColor);
    r = comps[0]; g = comps[1]; b = comps[2];
    //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    NSString *host = [[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"];
    NSString *request = [NSString stringWithFormat:@"http://%@/lights?red=%d&green=%d&blue=%d&node=%@",host,(int)(r*255), (int)(g*255), (int)(b*255), [node objectForKey:@"node"]];
   
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:request] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
    if (touchTimer) {
        [touchTimer invalidate];
    }
    touchTimer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(doSetColor:) userInfo:req repeats:NO];
}

- (void)colorPickerViewControllerRandom:(ColorPickerViewController *)colorPicker {
    NSString *host = [[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"];
    NSString *request = [NSString stringWithFormat:@"http://%@/lights?random=Random&node=%@",host, 
                         [node objectForKey:@"node"]];
    NSURLResponse *response = nil;
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:request] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
    [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:nil];
}

@end
