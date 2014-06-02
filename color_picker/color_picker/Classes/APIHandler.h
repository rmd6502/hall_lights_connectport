//
//  APIHandler.h
//  color_picker
//
//  Created by Robert Diamond on 6/1/14.
//
//

typedef void (^APIResponseCallback)(NSURLResponse *response, NSError *error, NSData *data);
@interface APIHandler : NSObject

+ (APIHandler *)sharedAPIHandler;

- (void)handleRequest:(NSURLRequest *)request withCallback:(APIResponseCallback)callback;
@end
