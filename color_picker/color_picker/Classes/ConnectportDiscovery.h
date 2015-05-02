//
//  ConnectportDiscovery.h
//  color_picker
//
//  Created by Robert Diamond on 4/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ADDPPacket;
@protocol ConnectportDiscoveryDelegate <NSObject>

- (void)foundConnectports:(ADDPPacket *)packet orError:(NSError *)error;

@end

//! Uses a subset of Digi's ADDP to find the local Connectports
@interface ConnectportDiscovery : NSObject

+ (void)findDigis;
+ (CFDataRef)newDiscoveryPacket;
+ (void)setDelegate:(id<ConnectportDiscoveryDelegate>)newDel;
+ (BOOL)isBusy;

@end
