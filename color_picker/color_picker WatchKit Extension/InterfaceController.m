//
//  InterfaceController.m
//  color_picker WatchKit Extension
//
//  Created by Robert Diamond on 12/3/14.
//
//

#import "InterfaceController.h"


@interface InterfaceController()
@property (weak, nonatomic) IBOutlet WKInterfaceSlider *red;
@property (weak, nonatomic) IBOutlet WKInterfaceSlider *green;
@property (weak, nonatomic) IBOutlet WKInterfaceSlider *blue;

@end


@implementation InterfaceController

- (instancetype)initWithContext:(id)context {
    self = [super initWithContext:context];
    if (self){
        // Initialize variables here.
        // Configure interface objects here.
        NSLog(@"%@ initWithContext", self);
        
    }
    return self;
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    NSLog(@"%@ will activate", self);
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    NSLog(@"%@ did deactivate", self);
}

@end



