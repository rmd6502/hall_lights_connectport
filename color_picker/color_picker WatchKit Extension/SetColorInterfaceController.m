//
//  SetColorInterfaceController.m
//  color_picker
//
//  Created by Robert Diamond on 4/26/15.
//
//

#import "SetColorInterfaceController.h"

@interface SetColorInterfaceController ()
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *lightNameLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceSlider *redSlider;
@property (weak, nonatomic) IBOutlet WKInterfaceSlider *greenSlider;
@property (weak, nonatomic) IBOutlet WKInterfaceSlider *blueSlider;

@end

@implementation SetColorInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



