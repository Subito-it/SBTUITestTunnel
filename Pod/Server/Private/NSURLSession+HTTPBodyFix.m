// NSURLSession+HTTPBodyFix.m
//
// Copyright (C) 2016 Subito.it S.r.l (www.subito.it)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if DEBUG
    #ifndef ENABLE_UITUNNEL 
        #define ENABLE_UITUNNEL 1
    #endif
#endif

#if ENABLE_UITUNNEL

#import "NSURLSession+HTTPBodyFix.h"
#import <SBTUITestTunnelCommon/SBTSwizzleHelpers.h>
#import <SBTUITestTunnelCommon/SBTUITestTunnel.h>

@implementation NSURLSession (HTTPBodyFix)

- (NSURLSessionUploadTask *)swz_uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData
{
    if ([request isKindOfClass:[NSMutableURLRequest class]] && bodyData) {
        [NSURLProtocol setProperty:bodyData forKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:(NSMutableURLRequest *)request];
    }
    
    return [self swz_uploadTaskWithRequest:request fromData:bodyData];
}

- (NSURLSessionUploadTask *)swz_uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL
{
    if ([request isKindOfClass:[NSMutableURLRequest class]]) {
        NSData *bodyData = [NSData dataWithContentsOfURL:fileURL];
        if (bodyData) {
            [NSURLProtocol setProperty:bodyData forKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:(NSMutableURLRequest *)request];
        }
    }
    
    return [self swz_uploadTaskWithRequest:request fromFile:fileURL];
}

- (NSURLSessionUploadTask *)swz_uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData completionHandler:(void (^)(NSData * __nullable data, NSURLResponse * __nullable response, NSError * __nullable error))completionHandler;
{
    if ([request isKindOfClass:[NSMutableURLRequest class]] && bodyData) {
        [NSURLProtocol setProperty:bodyData forKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:(NSMutableURLRequest *)request];
    }
    
    return [self swz_uploadTaskWithRequest:request fromData:bodyData completionHandler:completionHandler];
}

- (NSURLSessionUploadTask *)swz_uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL completionHandler:(void (^)(NSData * __nullable data, NSURLResponse * __nullable response, NSError * __nullable error))completionHandler;
{    
    return [self uploadTaskWithRequest:request fromFile:fileURL completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)swz_dataTaskWithRequest:(NSURLRequest *)request
{
    if ([request isKindOfClass:[NSMutableURLRequest class]] && request.HTTPBody) {
        [NSURLProtocol setProperty:request.HTTPBody forKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:(NSMutableURLRequest *)request];
    }
    
    return [self swz_dataTaskWithRequest:request];
}

- (NSURLSessionDataTask *)swz_dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
{
    if ([request isKindOfClass:[NSMutableURLRequest class]] && request.HTTPBody) {
        [NSURLProtocol setProperty:request.HTTPBody forKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:(NSMutableURLRequest *)request];
    }
    
    return [self swz_dataTaskWithRequest:request completionHandler:completionHandler];
}

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SBTTestTunnelInstanceSwizzle(self.class, @selector(uploadTaskWithRequest:fromData:), @selector(swz_uploadTaskWithRequest:fromData:));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(uploadTaskWithRequest:fromFile:), @selector(swz_uploadTaskWithRequest:fromFile:));
        
        SBTTestTunnelInstanceSwizzle(self.class, @selector(uploadTaskWithRequest:fromData:completionHandler:), @selector(swz_uploadTaskWithRequest:fromData:completionHandler:));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(uploadTaskWithRequest:fromFile:completionHandler:), @selector(swz_uploadTaskWithRequest:fromFile:completionHandler:));
        
        SBTTestTunnelInstanceSwizzle(self.class, @selector(dataTaskWithRequest:), @selector(swz_dataTaskWithRequest:));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(dataTaskWithRequest:completionHandler:), @selector(swz_dataTaskWithRequest:completionHandler:));
    });
}

@end

#endif
