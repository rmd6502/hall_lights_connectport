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
}

- (void)updateColorToRed:(NSNumber *)red green:(NSNumber *)green blue:(NSNumber *)blue {
    //NSLog(@"red %f green %f blue %f", self.red, self.green, self.blue);
    [WKInterfaceController openParentApplication:@{@"request": @"color", @"node": self.node, @"red": red, @"green": green, @"blue": blue} reply:^(NSDictionary *replyInfo, NSError *error) {
        NSLog(@"reply %@ error %@", replyInfo, error);
    }];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    if (rowIndex >= self.handler.allColorNames.count) {
        return;
    }
    NSString *colorName = self.handler.allColorNames[rowIndex];
    NSArray *components = self.handler.allColors[colorName];
    if ([components isKindOfClass:[NSArray class]]) {
        [self updateColorToRed:components[0] green:components[1] blue:components[2]];
    }
}

- (void)willActivate {
    [super willActivate];
    [self.colorListTable setNumberOfRows:self.handler.allColorNames.count withRowType:@"Color"];
    for (NSUInteger index = 0; index < self.colorListTable.numberOfRows; ++index) {
        ColorRow *row = [self.colorListTable rowControllerAtIndex:index];
        NSString *name = self.handler.allColorNames[index];
        UIColor *backgroundColor = [self.handler colorForName:name];
        [row.colorGroup setBackgroundColor:backgroundColor];
        CGFloat level, alpha;
        [backgroundColor getWhite:&level alpha:&alpha];
        [row.colorName setText:name];
        if (level > 0.5) {
            [row.colorName setTextColor:[UIColor blackColor]];
        } else {
            [row.colorName setTextColor:[UIColor whiteColor]];
        }
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



