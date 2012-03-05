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

@implementation ChooseLightViewController
@synthesize tbxml;
@synthesize tableView;
@synthesize spinner;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.title = @"Choose a Light";
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
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)setTbxml:(TBXML *)tbxml_ {
    spinner.hidden = YES;
    tbxml = tbxml_;
    [tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = 0;
    if (tbxml != nil && tbxml.rootXMLElement != nil) {
        for (TBXMLElement *element = [TBXML childElementNamed:@"light" parentElement:tbxml.rootXMLElement]; 
             element != nil; element = element->nextSibling) {
            ++count;
        }
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int count = 0;
    TBXMLElement *element = nil;
    if (tbxml != nil && tbxml.rootXMLElement != nil) {
        for (element = [TBXML childElementNamed:@"light" parentElement:tbxml.rootXMLElement]; 
             element != nil; element = element->nextSibling) {
            if (count == indexPath.row) break;
            ++count;
        }
    }
    if (element == nil) return nil;
    
    UITableViewCell *ret = [tableView_ dequeueReusableCellWithIdentifier:@"lightCell"];
    if (ret == nil) {
        ret = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"lightCell"];
    }
    
    ret.textLabel.text = [TBXML textForElement:[TBXML childElementNamed:@"nodeId" parentElement:element]];
    return ret;
}

- (void)tableView:(UITableView *)tableView_ didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int count = 0;
    TBXMLElement *element = nil;
    for (element = [TBXML childElementNamed:@"light" parentElement:tbxml.rootXMLElement]; 
         element != nil; element = element->nextSibling) {
        if (count == indexPath.row) break;
        ++count;
    }
    if (element == nil) return;
    node = [TBXML valueOfAttributeNamed:@"node" forElement:element];
    CGFloat r,g,b;
    r = [[TBXML textForElement:[TBXML childElementNamed:@"red" parentElement:element]] floatValue]/255.;
    g = [[TBXML textForElement:[TBXML childElementNamed:@"green" parentElement:element]] floatValue]/255.;;
    b = [[TBXML textForElement:[TBXML childElementNamed:@"blue" parentElement:element]] floatValue]/255.;;
    UIColor *currentColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
    //NSLog(@"color: %@", currentColor);
    
    ColorPickerViewController *cpvc = [[ColorPickerViewController alloc]initWithNibName:nil bundle:nil];
    cpvc.delegate = self;
    cpvc.defaultsColor = currentColor;
    [self.navigationController pushViewController:cpvc animated:YES];
    [cpvc release];
}

- (void)colorPickerViewController:(ColorPickerViewController *)colorPicker didSelectColor:(UIColor *)color {
    CGFloat r,g,b;
    const CGFloat *comps = CGColorGetComponents(color.CGColor);
    r = comps[0]; g = comps[1]; b = comps[2];
    //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    NSString *host = [[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"];
    NSString *request = [NSString stringWithFormat:@"http://%@/lights?red=%d&green=%d&blue=%d&node=%@",host,(int)(r*255), (int)(g*255), (int)(b*255), node];
    NSURLResponse *response = nil;
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:request] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
    [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:nil];
}

- (void)colorPickerViewControllerRandom:(ColorPickerViewController *)colorPicker {
    NSString *host = [[NSUserDefaults standardUserDefaults] stringForKey:@"arduino"];
    NSString *request = [NSString stringWithFormat:@"http://%@/lights?random=Random&node=%@",host, node];
    NSURLResponse *response = nil;
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:request] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
    [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:nil];
}

@end
