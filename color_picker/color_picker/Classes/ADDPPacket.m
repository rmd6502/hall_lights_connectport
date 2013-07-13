//
//  ADDPPacket.m
//  color_picker
//
//  Created by Robert Diamond on 4/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ADDPPacket.h"

@implementation ADDPPacket

@synthesize packetType;
@dynamic bytes;
@dynamic mac;
@dynamic ip;
@dynamic netmask;
@dynamic netName;
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


- (void)addField:(NSData *)data ofType:(Byte)dataType {
    [buffer setObject:data forKey:[NSNumber numberWithUnsignedChar:dataType]];
}
- (NSData *)extractFieldOfType:(Byte)dataType {
    return [buffer objectForKey:[NSNumber numberWithUnsignedChar:dataType]];
}
- (NSData *)bytes {
    uint16_t packet_length = 0;
    NSMutableData *ret = [NSMutableData data];
    [ret appendBytes:"DIGI" length:4];
    packet_type = CFSwapInt16HostToBig(packet_type);
    [ret appendBytes:&packet_type length:2];
    packet_type = CFSwapInt16BigToHost(packet_type);
    [ret appendBytes:&packet_length length:2];
    for (uint8_t i=0; i < ADDP_NUM_FIELDS ; ++i) {
        NSNumber *n = [NSNumber numberWithUnsignedChar:i];
        NSData *d = [buffer objectForKey:n];
        if (d) {
            packet_length += d.length;
            [ret appendBytes:&i length:1];
            [ret appendData:d];
        }
    }
    packet_length = CFSwapInt16HostToBig(packet_length);
    [ret replaceBytesInRange:NSMakeRange(6, 2) withBytes:&packet_length length:2];
    packet_length = CFSwapInt16BigToHost(packet_length);
    
    return ret;
}
- (void)setBytes:(NSData *)bytes {
    uint16_t shortTemp;
    int16_t packet_length = 0;
    NSRange r;
    
    if (bytes.length < 9) {
        NSLog(@"data too short");
        return;
    }
    char sig[5] = {0};
    [bytes getBytes:sig length:4];
    if (strcasecmp(sig, "digi")) {
        NSLog(@"Magic didn't match");
        return;
    }
    [buffer removeAllObjects];
    r.location = 4;
    r.length = 2;
    [bytes getBytes:&shortTemp range:r];
    r.location += r.length;
    packet_type = CFSwapInt16BigToHost(shortTemp);
    [bytes getBytes:&shortTemp range:r];
    packet_length = CFSwapInt16BigToHost(shortTemp);
    r.location += r.length;
    while (packet_length > 0) {
        uint8_t field_type, field_length;
        r.length = 1;
        [bytes getBytes:&field_type range:r];
        r.location += r.length;
        [bytes getBytes:&field_length range:r];
        r.location += r.length;
        r.length = field_length;
        NSMutableData *fd = [NSMutableData dataWithLength:field_length];
        [bytes getBytes:[fd mutableBytes] range:r];
        r.location += r.length;
        packet_length -= field_length + 2;
        [buffer setObject:fd forKey:[NSNumber numberWithUnsignedChar:field_type]];
    }
}

- (UInt32)ip {
    NSData *ipValue = [buffer objectForKey:[NSNumber numberWithUnsignedChar:ADDP_IP]];
    if (ipValue == nil) {
        return (UInt32)-1;
    }
    UInt32 ret = 0;
    memcpy(&ret, ipValue.bytes, sizeof(ret));
    ret = CFSwapInt32LittleToHost(ret);
    return ret;
}

- (NSString *)deviceName {
    NSData *dnValue = [buffer objectForKey:[NSNumber numberWithUnsignedChar:ADDP_DEVICE_NAME]];
    if (dnValue == nil) {
        return nil;
    }
    return [[NSString alloc] initWithBytes:dnValue.bytes length:dnValue.length encoding:NSUTF8StringEncoding];
}

- (NSString *)netName {
    NSData *dnValue = [buffer objectForKey:[NSNumber numberWithUnsignedChar:ADDP_NETNAME]];
    if (dnValue == nil) {
        return nil;
    }
    return [[NSString alloc] initWithBytes:dnValue.bytes length:dnValue.length encoding:NSUTF8StringEncoding];
}
@end
