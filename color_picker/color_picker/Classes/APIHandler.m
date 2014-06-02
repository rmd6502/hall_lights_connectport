//
//  APIHandler.m
//  color_picker
//
//  Created by Robert Diamond on 6/1/14.
//
//

#import "APIHandler.h"

@interface APIHandler ()<NSURLConnectionDataDelegate>

@property (nonatomic) NSOperationQueue *apiQueue;

@end

@implementation APIHandler

+ (APIHandler *)sharedAPIHandler
{
    static APIHandler *sharedInstance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [APIHandler new];
    });
    return sharedInstance;
}

- (id)init
{
    if ((self = [super init])) {
        _apiQueue = [NSOperationQueue new];
        _apiQueue.name = @"API Queue";
    }
    return self;
}

- (void)handleRequest:(NSURLRequest *)request withCallback:(APIResponseCallback)callback
{
    [NSURLConnection sendAsynchronousRequest:request queue:_apiQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (callback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(response, connectionError, data);
            });
        }
    }];
}
@end
