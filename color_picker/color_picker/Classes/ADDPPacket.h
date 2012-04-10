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
    ADDP_ENCRYPTED_PORT,
    
    ADDP_NUM_FIELDS
};

enum PacketTypes {
    PACKET_TYPE_UNSET,
    PACKET_TYPE_DISCOVERY_REQUEST,
    PACKET_TYPE_DISCOVERY_RESPONSE,
    PACKET_TYPE_NETCONFIG_REQUEST,
    PACKET_TYPE_NETCONFIG_RESPONSE,
    PACKET_TYPE_REBOOT_REQUEST,
    PACKET_TYPE_REBOOT_RESPONSE,
    PACKET_TYPE_DHCP_REQUEST,
    PACKET_TYPE_DHCP_RESPONSE  
};

@interface ADDPPacket : NSObject {
    NSMutableDictionary *buffer;
    uint16_t packet_type;
}

@property (nonatomic, assign) UInt16 packetType;
@property (nonatomic, assign) NSData *bytes;
@property (nonatomic, assign) UInt64 mac;
@property (nonatomic, assign) UInt32 ip;
@property (nonatomic, assign) UInt32 netmask;
@property (nonatomic, assign) NSString *netName;
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
