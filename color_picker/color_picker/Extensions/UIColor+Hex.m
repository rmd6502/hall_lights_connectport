//
//  UIColor+Hex.m
//  color_picker
//
//  Created by Robert Diamond on 4/26/15.
//
//

#import "UIColor+Hex.h"

@implementation UIColor(Hex)

- (NSString *)hexString {
    CGFloat red, green, blue, alpha;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    return [NSString stringWithFormat:@"%02x%02x%02x", (UInt16)(red*255.0), (UInt16)(green*255.0), (UInt16)(blue*255.0)];
}

+ (instancetype)colorWithHexString:(NSString *)hexString {
    int red, green, blue;
    const char *hexCString = [hexString cStringUsingEncoding:NSUTF8StringEncoding];
    sscanf(hexCString, "%02x%02x%02x", &red, &green, &blue);
    return [UIColor colorWithRed:(CGFloat)red/255.0 green:(CGFloat)green/255.0 blue:(CGFloat)blue/255.0 alpha:1.0];
}

@end
