//
//  UIColor+Hex.h
//  color_picker
//
//  Created by Robert Diamond on 4/26/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIColor(Hex)
- (NSString *)hexString;
+ (instancetype)colorWithHexString:(NSString *)hexString;
@end
