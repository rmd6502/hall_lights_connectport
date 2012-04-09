//
//  ConnectportDiscovery.m
//  color_picker
//
//  Created by Robert Diamond on 4/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <sys/socket.h>
#import <netinet/in.h>
#import <netdb.h>
#import "ConnectportDiscovery.h"

void gotData(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

@implementation ConnectportDiscovery

+ (void)findDigis {
    CFSocketRef sock = CFSocketCreate(nil, AF_INET, SOCK_DGRAM, 0, kCFSocketDataCallBack, gotData, nil);
    int s = CFSocketGetNative(sock);
    Byte loop = 0;
    setsockopt(s, IPPROTO_IP, IP_MULTICAST_LOOP, &loop, sizeof(loop));
    uint32_t any = INADDR_ANY;
    struct addrinfo hint, *res=nil;
    memset(&hint, 0, sizeof(hint));
    hint.ai_flags = AI_NUMERICHOST | AI_NUMERICSERV;
    hint.ai_family = PF_UNSPEC;
    getaddrinfo("224.0.5.128", "2362", &hint, &res);
    struct ip_mreq mreq;
    memcpy(&mreq.imr_interface, &any, sizeof(mreq.imr_interface));
    memcpy(&mreq.imr_multiaddr, &res->ai_addr[0].sa_data[2], sizeof(mreq.imr_multiaddr));
    setsockopt(s, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq, sizeof(mreq));
    
    CFDataRef sendAddr = CFDataCreate(nil, (const uint8_t *)&res->ai_addr[0].sa_data[2], sizeof(in_addr_t));
    CFDataRef packet = [ConnectportDiscovery createDiscoveryPacket];
    CFSocketSendData(sock, sendAddr, packet, 5);
    CFRelease(packet);
    CFRelease(sendAddr);
}

void gotData(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    CFDataRef recv = (CFDataRef)data;
    NSLog(@"received %@", recv);
}

+ (CFDataRef)createDiscoveryPacket {
    uint8_t packet[] = { 'D','I','G','I', 0,1, 0,6, 0xff,0xff,0xff,0xff,0xff,0xff };
    return CFDataCreate(nil, packet, sizeof(packet));
    
}
@end
