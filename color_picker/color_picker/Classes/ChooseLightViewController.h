//
//  ChooseLightViewController.h
//  color_picker
//
//  Created by Robert Diamond on 3/4/12.
//  Copyright (c) 2012 America Online. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ColorPickerViewController.h"

@class TBXML;
@interface ChooseLightViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, ColorPickerViewControllerDelegate, UINavigationControllerDelegate,UIAlertViewDelegate> {
    NSMutableDictionary *lightColors;
    NSTimer *refreshTimer;
    NSTimer *touchTimer;
    ColorPickerViewController *cpvc;
}

@property (nonatomic, unsafe_unretained) IBOutlet UITableView *tableView;
@property (nonatomic, unsafe_unretained) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) TBXML *tbxml;
@property (nonatomic, strong) UIBarButtonItem *refresh;
@property (nonatomic, strong) NSMutableDictionary *node;

- (IBAction)doRefresh:(id)sender;
- (IBAction)allLightsOn:(id)sender;
- (IBAction)allLightsOff:(id)sender;

- (void)doSetColor:(NSTimer *)req;
- (void)updateTable;
- (void)backgroundRequest:(NSURLRequest *)req;

@end
