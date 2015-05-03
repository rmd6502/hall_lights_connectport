//
//  ColorHandler.h
//  color_picker
//
//  Created by Robert Diamond on 5/2/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ColorHandler : NSObject

- (NSArray *)allColorNames;
- (NSDictionary *)allColors;

+ (instancetype)sharedColorHandler;

- (UIColor *)colorForName:(NSString *)name;

@end
