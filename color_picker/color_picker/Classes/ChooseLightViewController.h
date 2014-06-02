//
//  ChooseLightViewController.h
//  color_picker
//
//  Created by Robert Diamond on 3/4/12.
//  Copyright (c) 2012 Robert Diamond. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ColorPickerViewController.h"

@interface Light : NSObject

@property (nonatomic,copy) NSString *name;
@property (nonatomic) UIColor *color1;
@property (nonatomic) UIColor *color2;
@property (nonatomic) NSString *nodeID;
@property (nonatomic) NSDate *lastActive;

@end

@interface ChooseLightViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, ColorPickerViewControllerDelegate, UINavigationControllerDelegate,UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic) UIBarButtonItem *refresh;
@property (nonatomic) NSMutableDictionary *node;
@property (nonatomic) NSArray *lights;

- (IBAction)doRefresh:(id)sender;
- (IBAction)allLightsOn:(id)sender;
- (IBAction)allLightsOff:(id)sender;

- (void)doSetColor:(NSTimer *)req;
- (void)updateTable;
- (void)backgroundRequest:(NSURLRequest *)req;

@end
