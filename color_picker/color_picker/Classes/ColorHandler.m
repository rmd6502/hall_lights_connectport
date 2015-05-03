//
//  ColorHandler.m
//  color_picker
//
//  Created by Robert Diamond on 5/2/15.
//
//

#import <UIKit/UIKit.h>
#import "ColorHandler.h"

static const NSString *const rgbFile = @"rgb.txt";

@interface ColorHandler ()

@property (nonatomic) NSArray *allColorNames;
@property (nonatomic) NSDictionary *allColors;
@property (nonatomic) dispatch_queue_t workQ;

- (void)readColorList;

@end

static ColorHandler *s_sharedInstance = nil;
static dispatch_once_t once = 0;

@implementation ColorHandler

+ (void)initialize
{
    [[self sharedColorHandler] readColorList];
}

+ (instancetype)sharedColorHandler
{
    dispatch_once(&once, ^{
        s_sharedInstance = [[ColorHandler alloc] init];
        s_sharedInstance.workQ = dispatch_queue_create("Color Handler", DISPATCH_QUEUE_SERIAL);
    });
    return s_sharedInstance;
}

- (void)readColorList
{
    dispatch_async(self.workQ, ^{
        NSMutableDictionary *allColors = [@{@"Black": [UIColor blackColor]} mutableCopy];
        NSMutableArray *allColorNames = [@[@"Black"] mutableCopy];

        NSString *path = [[NSBundle mainBundle] pathForResource:@"rgb" ofType:@"txt"];
        NSData *rgbData = nil;
        if (path.length) {
            rgbData = [[NSFileManager defaultManager] contentsAtPath:path];
        }
        NSRange redRange = NSMakeRange(0, 3);
        NSRange greenRange = NSMakeRange(4, 3);
        NSRange blueRange = NSMakeRange(8, 3);
        NSRange nameRange = NSMakeRange(13, 999);

        if (rgbData.length) {
            NSArray *rgbLines = [[[NSString alloc] initWithData:rgbData encoding:NSUTF8StringEncoding] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            for (NSString *rgbDatum in rgbLines) {
                if (rgbDatum.length && ![rgbDatum hasPrefix:@"#"]) {  // skip empty lines caused by adjacent newline chars
                    CGFloat red = [[rgbDatum substringWithRange:redRange] doubleValue]/255.0;
                    CGFloat green = [[rgbDatum substringWithRange:greenRange] doubleValue]/255.0;
                    CGFloat blue = [[rgbDatum substringWithRange:blueRange] doubleValue]/255.0;
                    NSString *name = [rgbDatum substringFromIndex:nameRange.location];
                    if (name.length && ![name isEqualToString:@"black"] && [name rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet] options:0].location != 0) {
                        name = [name capitalizedString];
                        [allColorNames addObject:name];
                        allColors[name] = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
                    }
                }
            }
        }
        self.allColors = [allColors copy];
        self.allColorNames = [allColorNames copy];
    });
}

- (UIColor *)colorForName:(NSString *)name
{
    dispatch_sync(self.workQ, ^{
        // just need to wait until the readColors block has finished
    });
    return self.allColors[name];
}

- (NSArray *)allColorNames
{
    dispatch_sync(self.workQ, ^{
        // just need to wait until the readColors block has finished
    });
    return _allColorNames;
}

- (NSDictionary *)allColors
{
    dispatch_sync(self.workQ, ^{
        // just need to wait until the readColors block has finished
    });
    return _allColors;
}
@end
