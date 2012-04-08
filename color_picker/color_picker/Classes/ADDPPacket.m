//
//  ADDPPacket.m
//  color_picker
//
//  Created by Robert Diamond on 4/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ADDPPacket.h"

@implementation ADDPPacket

@dynamic packetType;
@dynamic bytes;
@dynamic mac;
@dynamic ip;
@dynamic netmask;
@dynamic netname;
@dynamic fwVersion;
@dynamic result;
@dynamic resultFlag;
@dynamic gateway;
@dynamic configError;
@dynamic deviceName;
@dynamic portNumber;
@dynamic unknownIP;
@dynamic dhcpEnabled;
@dynamic errorCode;
@dynamic serialPorts;
@dynamic encryptedPort;

- (id)init {
    if ((self = [super init]) != nil) {
        buffer = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [buffer release];
    [super dealloc];
}

- (void)addField:(NSData *)data ofType:(Byte)dataType {
    [buffer setObject:data forKey:[NSNumber numberWithUnsignedChar:dataType]];
}
- (NSData *)extractFieldOfType:(Byte)dataType {
    return [buffer objectForKey:[NSNumber numberWithUnsignedChar:dataType]];
}
- (NSData *)bytes {
    
}
- (void)setBytes:(NSData *)bytes {
    
}

@end
