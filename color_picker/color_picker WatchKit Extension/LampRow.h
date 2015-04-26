//
//  LampRow.h
//  color_picker
//
//  Created by Robert Diamond on 4/26/15.
//
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface LampRow : NSObject
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *lightColorGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *lightColorLabel;

@end
