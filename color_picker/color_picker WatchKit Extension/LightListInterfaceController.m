//
//  LightListInterfaceController.m
//  color_picker WatchKit Extension
//
//  Created by Robert Diamond on 4/25/15.
//
//

#import "ErrorRow.h"
#import "LampRow.h"
#import "LightListInterfaceController.h"
#import "UIColor+Hex.h"

@interface LightListInterfaceController()
@property (weak, nonatomic) IBOutlet WKInterfaceTable *lightListTable;
@property (nonatomic) NSDictionary *lights;
@property (nonatomic) NSArray *lightNames;
@end


@implementation LightListInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
    [self.lightListTable setRowTypes:@[@"Waiting"]];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    [self _reloadTable];
}

- (void)_reloadTable {
    [self.lightListTable setRowTypes:@[@"Waiting"]];
    __weak typeof(self) weakSelf = self;
    [WKInterfaceController openParentApplication:@{@"request": @"lights"} reply:^(NSDictionary *replyInfo, NSError *error) {
        typeof (self) strongSelf = weakSelf;
        if (strongSelf) {
            if (replyInfo[@"lights"] && [replyInfo[@"lights"] isKindOfClass:[NSDictionary class]]) {
                strongSelf.lights = replyInfo[@"lights"];
            } else {
                strongSelf.lights = nil;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf updateTable];
            });
        }
    }];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (void)updateTable {
    if (self.lights.count) {
        [self.lightListTable setNumberOfRows:self.lights.count withRowType:@"Lamp"];
        self.lightNames = [[self.lights allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [(NSString *)obj1 compare:(NSString *)obj2];
        }];
    } else {
        [self.lightListTable setRowTypes:@[@"Error"]];
    }
    for (NSUInteger row = 0; row < self.lightListTable.numberOfRows; ++row) {
        NSObject *controller = [self.lightListTable rowControllerAtIndex:row];
        if ([controller isKindOfClass:[LampRow class]]) {
            LampRow *lampRow = (LampRow *)controller;
            NSString *key = self.lightNames[row];
            NSDictionary *light = self.lights[key];
            UIColor *lightColor = [UIColor colorWithHexString:light[@"color"]];
            [lampRow.lightColorGroup setBackgroundColor:lightColor];
            [lampRow.lightColorLabel setText:(NSString *)self.lightNames[row]];
        } else if ([controller isKindOfClass:[ErrorRow class]]) {
            [[(ErrorRow *)controller errorLabel] setText:@"Failed to retrieve lights"];
        }
    }
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    [super table:table didSelectRowAtIndex:rowIndex];
    ErrorRow *row = [table rowControllerAtIndex:rowIndex];
    if ([row isKindOfClass:[ErrorRow class]]) {
        [self _reloadTable];
    }
}

- (id)contextForSegueWithIdentifier:(NSString *)segueIdentifier inTable:(WKInterfaceTable *)table rowIndex:(NSInteger)rowIndex
{
    NSString *name = self.lightNames[rowIndex];
    return @{@"name":name, @"color": self.lights[name][@"color"], @"node": self.lights[name][@"node"]};
}

@end



