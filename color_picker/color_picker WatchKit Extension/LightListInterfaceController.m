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

@interface LightListInterfaceController()
@property (weak, nonatomic) IBOutlet WKInterfaceTable *lightListTable;
@property (nonatomic) NSDictionary *lights;
@end


@implementation LightListInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];

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
    NSArray *lightNames = nil;
    if (self.lights.count) {
        [self.lightListTable setNumberOfRows:self.lights.count withRowType:@"Lamp"];
        lightNames = [[self.lights allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [(NSString *)obj1 compare:(NSString *)obj2];
        }];
    } else {
        [self.lightListTable setRowTypes:@[@"Error"]];
    }
    for (NSUInteger row = 0; row < self.lightListTable.numberOfRows; ++row) {
        NSObject *controller = [self.lightListTable rowControllerAtIndex:row];
        if ([controller isKindOfClass:[LampRow class]]) {
            LampRow *lampRow = (LampRow *)controller;
            [lampRow.lightColorGroup setBackgroundColor:[UIColor whiteColor]];
            [lampRow.lightColorLabel setText:(NSString *)lightNames[row]];
        } else if ([controller isKindOfClass:[ErrorRow class]]) {
            [[(ErrorRow *)controller errorLabel] setText:@"Failed to retrieve lights"];
        }
    }
}

@end



