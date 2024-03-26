//
//  SBTRequestProperty.m
//  SBTUITestTunnelCommon
//
//  Created by tomas on 20/02/24.
//

#import "include/SBTRequestPropertyStorage.h"

@implementation SBTRequestPropertyStorage

static NSMutableDictionary *storage;
static dispatch_queue_t queue;

+ (void)initialize 
{
    if (self == [SBTRequestPropertyStorage class]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            storage = [[NSMutableDictionary alloc] init];
            queue = dispatch_queue_create("com.subito.sbtuitesttunnel.storage.queue", DISPATCH_QUEUE_SERIAL);
        });
    }
}

+ (void)setProperty:(id)property forKey:(nonnull NSString *)key inRequest:(nonnull NSMutableURLRequest *)request
{
    if ([property isKindOfClass:[NSData class]] && ((NSData *)property).length > 16834) {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        dispatch_sync(queue, ^{ 
            [storage setObject:property forKey:uuid];
            [NSURLProtocol setProperty:uuid forKey:key inRequest:request];
        });        
    } else {
        [NSURLProtocol setProperty:property forKey:key inRequest:request];
    }
}

+ (id)propertyForKey:(NSString *)key inRequest:(NSURLRequest *)request;
{    
    __block id result = nil;

    dispatch_sync(queue, ^{
        id property = [NSURLProtocol propertyForKey:key inRequest:request];
        result = [storage objectForKey:property] ?: property;
    });

    return result;
}

@end
