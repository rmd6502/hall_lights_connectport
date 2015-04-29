//
//  SetColorInterfaceController.m
//  color_picker
//
//  Created by Robert Diamond on 4/26/15.
//
//

#import <UIKit/UIKit.h>
#import "SetColorInterfaceController.h"
#import "UIColor+Hex.h"

@interface SetColorInterfaceController ()
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *lightNameLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceSlider *redSlider;
@property (weak, nonatomic) IBOutlet WKInterfaceSlider *greenSlider;
@property (weak, nonatomic) IBOutlet WKInterfaceSlider *blueSlider;

@property (nonatomic) CGFloat red;
@property (nonatomic) CGFloat green;
@property (nonatomic) CGFloat blue;

@property (nonatomic) NSUInteger node;

@end

@implementation SetColorInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    if ([context isKindOfClass:[NSDictionary class]]) {
        self.color = [UIColor colorWithHexString:context[@"color"]];
        [self.lightNameLabel setText:context[@"name"]];
    }
}

- (void)willActivate {
    [super willActivate];
    CGFloat alpha;

    [self.color getRed:&_red green:&_green blue:&_blue alpha:&alpha];
    [self.redSlider setValue:self.red];
    [self.greenSlider setValue:self.green];
    [self.blueSlider setValue:self.blue];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    self.color = [UIColor colorWithRed:self.red green:self.green blue:self.blue alpha:1.0];
}

- (IBAction)updateRed:(float)value {
    self.red = value;
    [self updateColor];
}
- (IBAction)updateGreen:(float)value {
    self.green = value;
    [self updateColor];
}
- (IBAction)updateBlue:(float)value {
    self.blue = value;
    [self updateColor];
}

- (void)updateColor {
    NSLog(@"red %f green %f blue %f", self.red, self.green, self.blue);
    [WKInterfaceController openParentApplication:@{@"request": @"color", @"node": @(self.node), @"red": @(self.red), @"green": @(self.green), @"blue": @(self.blue)} reply:^(NSDictionary *replyInfo, NSError *error) {
        NSLog(@"reply %@ error %@", replyInfo, error);
    }];
}

@end



