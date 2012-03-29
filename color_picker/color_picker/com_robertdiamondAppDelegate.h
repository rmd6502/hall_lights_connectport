//
//  com_robertdiamondAppDelegate.h
//  color_picker
//
//  Created by Robert Diamond on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ColorPickerViewController.h"
#import "ChooseLightViewController.h"

@class TBXML;
@class ChooseLightViewController;
@interface com_robertdiamondAppDelegate : UIResponder <UIApplicationDelegate> {
    ChooseLightViewController *clvc;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ChooseLightViewController *viewController;

@end
