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
@interface ChooseLightViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, ColorPickerViewControllerDelegate> {
    NSMutableDictionary *lightColors;
    NSTimer *refreshTimer;
    NSTimer *touchTimer;
    ColorPickerViewController *cpvc;
}

@property (nonatomic, assign) IBOutlet UITableView *tableView;
@property (nonatomic, assign) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, retain) TBXML *tbxml;
@property (nonatomic, retain) UIBarButtonItem *refresh;
@property (nonatomic, retain) NSMutableDictionary *node;

- (IBAction)doRefresh:(id)sender;
- (void)doSetColor:(NSTimer *)req;
- (void)updateTable;

@end
