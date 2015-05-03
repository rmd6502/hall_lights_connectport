//
//  ColorRow.h
//  color_picker
//
//  Created by Robert Diamond on 5/2/15.
//
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface ColorRow : NSObject
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *colorName;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *colorGroup;

@end
