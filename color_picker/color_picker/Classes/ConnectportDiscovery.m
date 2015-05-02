//
//  ConnectportDiscovery.m
//  color_picker
//
//  Created by Robert Diamond on 4/8/12.
//  Copyright (c) 2012 Robert M Diamond. All rights reserved.
//

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>
#import "ConnectportDiscovery.h"
#import "ADDPPacket.h"

void gotData(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

id<ConnectportDiscoveryDelegate> delegate = nil;
CFSocketRef sock = nil;

@interface ConnectportDiscovery(Private)
+ (void)timeoutFinished:(NSTimer *)t;
@end

@implementation ConnectportDiscovery

+ (void)findDigis {
    if (sock) {
        CFSocketInvalidate(sock);
        CFRelease(sock);
    }
    sock = CFSocketCreate(nil, AF_INET, SOCK_DGRAM, 0, kCFSocketDataCallBack, gotData, nil);
    int s = CFSocketGetNative(sock);
    Byte loop = 0;
    setsockopt(s, IPPROTO_IP, IP_MULTICAST_LOOP, &loop, sizeof(loop));
    uint32_t any = INADDR_ANY;
    struct sockaddr_in dest;
    memset(&dest, 0, sizeof(dest));
    dest.sin_port = htons(2362);
    dest.sin_family = AF_INET;
    in_addr_t dest_addr = inet_addr("224.0.5.128");
    memcpy(&dest.sin_addr, &dest_addr, sizeof(dest.sin_addr));
    struct ip_mreq mreq;
    memcpy(&mreq.imr_interface, &any, sizeof(mreq.imr_interface));
    memcpy(&mreq.imr_multiaddr, &dest_addr, sizeof(mreq.imr_multiaddr));
    setsockopt(s, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq, sizeof(mreq));
    
    CFDataRef sendAddr = CFDataCreate(nil, (const uint8_t *)&dest, sizeof(dest));
    CFDataRef packet = [ConnectportDiscovery newDiscoveryPacket];
    CFSocketSendData(sock, sendAddr, packet, 2.5);
    CFRelease(packet);
    CFRelease(sendAddr);
    
    CFRunLoopSourceRef rlr = CFSocketCreateRunLoopSource(nil, sock, 1);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), rlr, kCFRunLoopCommonModes);
    CFRelease(rlr);
    
    [NSTimer scheduledTimerWithTimeInterval:15.0 target:[ConnectportDiscovery class] selector:@selector(timeoutFinished:) userInfo:nil repeats:NO];
}

+ (void)timeoutFinished:(NSTimer *)t {
    [t invalidate];
    if (sock) {
        CFSocketInvalidate(sock);
        CFRelease(sock);
        sock = nil;
    }
    if (delegate) {
        NSError *err = [NSError errorWithDomain:@"Discovery" 
                                           code:-3141 
                                       userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                 @"Hit Timeout", NSLocalizedDescriptionKey, nil]];
        [delegate performSelector:@selector(foundConnectports:orError:) withObject:nil withObject:err];
    }
}

void gotData(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    CFDataRef rcvd = (CFDataRef)data;
    NSLog(@"received %@", rcvd);
    ADDPPacket *p = [[ADDPPacket alloc] init];
    p.bytes = (__bridge NSData *)rcvd;
    struct in_addr ina;
    if (p.ip == (uint32_t)-1) {
        NSLog(@"invalid ip address - skipping");
        if (delegate) {
            [delegate performSelector:@selector(foundConnectports:orError:)
                           withObject:nil
                           withObject:[NSError errorWithDomain:@"Discovery" code:1111 userInfo:@{NSLocalizedDescriptionKey:@"invalid ip address in response"}]];
        }
        return;
    }
    ina.s_addr = p.ip;
    NSLog(@"Found %s name %@ netname %@", inet_ntoa(ina), p.deviceName, p.netName);
    if (delegate) {
        [delegate performSelector:@selector(foundConnectports:orError:) withObject:p withObject:nil];
    }
}

+ (CFDataRef)newDiscoveryPacket {
    uint8_t packet[] = { 'D','I','G','I', 0,1, 0,6, 0xff,0xff,0xff,0xff,0xff,0xff };
    return CFDataCreate(nil, packet, sizeof(packet));
    
}

+ (void)setDelegate:(id<ConnectportDiscoveryDelegate>)newDel {
    delegate = newDel;
}

+ (BOOL)isBusy
{
    return sock != nil;
}
@end
