//
//  SetColorListInterfaceController.m
//  color_picker
//
//  Created by Robert Diamond on 5/2/15.
//
//

#import "ColorHandler.h"
#import "ColorRow.h"
#import "SetColorListInterfaceController.h"
#import "UIColor+Hex.h"

@interface SetColorListInterfaceController ()

@property (nonatomic) ColorHandler *handler;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *lightNameLabel;
@property (nonatomic) NSString *node;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *colorListTable;
@property (nonatomic) NSUInteger selectedRow;

@end

@implementation SetColorListInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    self.handler = [ColorHandler sharedColorHandler];
    if ([context isKindOfClass:[NSDictionary class]]) {
        self.color = [UIColor colorWithHexString:context[@"color"]];
        [self.lightNameLabel setText:context[@"name"]];
        self.node = context[@"node"];
    }
    self.selectedRow = NSNotFound;
}

- (void)updateColorToColor:(UIColor *)newColor {
    self.color = newColor;
    CGFloat red, green, blue, alpha;
    [newColor getRed:&red green:&green blue:&blue alpha:&alpha];
    //NSLog(@"red %f green %f blue %f", self.red, self.green, self.blue);
    [WKInterfaceController openParentApplication:@{@"request": @"color", @"node": self.node, @"red": @(red), @"green": @(green), @"blue": @(blue)} reply:^(NSDictionary *replyInfo, NSError *error) {
        NSLog(@"reply %@ error %@", replyInfo, error);
    }];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    if (rowIndex >= self.handler.allColorNames.count) {
        return;
    }
    if (rowIndex != self.selectedRow) {
        if (self.selectedRow != NSNotFound) {
            ColorRow *row = [self.colorListTable rowControllerAtIndex:self.selectedRow];
            [row.outlineGroup setBackgroundColor:[UIColor clearColor]];
        }
        self.selectedRow = rowIndex;
    }
    NSString *colorName = self.handler.allColorNames[rowIndex];
    UIColor *newColor = self.handler.allColors[colorName];
    if ([newColor isKindOfClass:[UIColor class]]) {
        CGFloat level, alpha;
        [newColor getWhite:&level alpha:&alpha];
        ColorRow *row = [self.colorListTable rowControllerAtIndex:self.selectedRow];
        if (level > 0.5) {
            [row.outlineGroup setBackgroundColor:[UIColor darkGrayColor]];
        } else {
            [row.outlineGroup setBackgroundColor:[UIColor whiteColor]];
        }
        [self updateColorToColor:newColor];
    }
}

- (void)willActivate {
    [super willActivate];
    [self.colorListTable setNumberOfRows:self.handler.allColorNames.count withRowType:@"Color"];
    for (NSUInteger index = 0; index < self.colorListTable.numberOfRows; ++index) {
        ColorRow *row = [self.colorListTable rowControllerAtIndex:index];
        NSString *name = self.handler.allColorNames[index];
        UIColor *cellColor = [self.handler colorForName:name];
        UIColor *backgroundColor = cellColor;
        [row.colorGroup setBackgroundColor:backgroundColor];
        CGFloat level, alpha;
        [backgroundColor getWhite:&level alpha:&alpha];
        [row.colorName setText:name];
        if (level > 0.5) {
            [row.colorName setTextColor:[UIColor blackColor]];
        } else {
            [row.colorName setTextColor:[UIColor whiteColor]];
        }
        if ([self.color isEqual:cellColor]) {
            if (self.selectedRow == NSNotFound) {
                self.selectedRow = index;
            }
            if (level > 0.5) {
                [row.outlineGroup setBackgroundColor:[UIColor darkGrayColor]];
            } else {
                [row.outlineGroup setBackgroundColor:[UIColor whiteColor]];
            }
        } else {
            [row.outlineGroup setBackgroundColor:[UIColor clearColor]];
        }
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



