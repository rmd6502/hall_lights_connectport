//
//  ADDPPacket.h
//  color_picker
//
//  Created by Robert Diamond on 4/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

enum DataTypes {
    ADDP_NONE,
    ADDP_MAC,
    ADDP_IP,
    ADDP_NETMASK,
    ADDP_NETNAME,
    UNKNOWN1,
    UNKNOWN2,
    UNKNOWN3,
    ADDP_FIRMWARE,
    ADDP_RESULT,
    ADDP_RESULT_FLAG,
    ADDP_GATEWAY,
    ADDP_CONFIG_ERROR,
    ADDP_DEVICE_NAME,
    ADDP_PORT_NUM,
    ADDP_UNKNOWN_IP,
    ADDP_DHCP_ENABLED,
    ADDP_ERROR,
    ADDP_SERIAL_PORTS,
    ADDP_ENCRYPTED_PORT
};

@interface ADDPPacket : NSObject {
    NSMutableDictionary *buffer;
}

@property (nonatomic, assign) UInt16 packetType;
@property (nonatomic, assign) NSData *bytes;
@property (nonatomic, assign) UInt64 mac;
@property (nonatomic, assign) UInt32 ip;
@property (nonatomic, assign) UInt32 netmask;
@property (nonatomic, assign) NSString *netname;
@property (nonatomic, assign) NSString *fwVersion;
@property (nonatomic, assign) NSString *result;
@property (nonatomic, assign) UInt8 resultFlag;
@property (nonatomic, assign) UInt32 gateway;
@property (nonatomic, assign) UInt16 configError;
@property (nonatomic, assign) NSString *deviceName;
@property (nonatomic, assign) UInt32 portNumber;
@property (nonatomic, assign) UInt32 unknownIP;
@property (nonatomic, assign) UInt8 dhcpEnabled;
@property (nonatomic, assign) UInt8 errorCode;
@property (nonatomic, assign) UInt8 serialPorts;
@property (nonatomic, assign) UInt32 encryptedPort;

- (void)addField:(NSData *)data ofType:(Byte)dataType;
- (NSData *)extractFieldOfType:(Byte)dataType;

@end
