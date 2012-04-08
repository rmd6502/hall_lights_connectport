//
//  ConnectportDiscovery.h
//  color_picker
//
//  Created by Robert Diamond on 4/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Uses a subset of Digi's ADDP to find the local Connectports
@interface ConnectportDiscovery : NSObject

+ (NSArray *)findDigis;

@end
