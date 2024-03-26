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

@import SBTUITestTunnelCommon;

#import "NSURLSession+HTTPBodyFix.h"

@implementation NSURLSession (HTTPBodyFix)

- (NSURLSessionUploadTask *)swz_uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData
{
    // remove the body to avoid a CFNetwork warning
    NSURLRequest *requestWithoutBody = [request sbt_copyWithoutBody];

    if ([requestWithoutBody isKindOfClass:[NSMutableURLRequest class]] && bodyData) {
        [SBTRequestPropertyStorage setProperty:bodyData forKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:(NSMutableURLRequest *)requestWithoutBody];

        // mark this as an upload request so future code knows to find the body via NSURLProtocol instead
        [requestWithoutBody sbt_markUploadTaskRequest];
    }
    
    return [self swz_uploadTaskWithRequest:requestWithoutBody fromData:bodyData];
}

- (NSURLSessionUploadTask *)swz_uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL
{
    // remove the body to avoid a CFNetwork warning
    NSURLRequest *requestWithoutBody = [request sbt_copyWithoutBody];

    if ([requestWithoutBody isKindOfClass:[NSMutableURLRequest class]]) {
        NSData *bodyData = [NSData dataWithContentsOfURL:fileURL];
        if (bodyData) {
            [SBTRequestPropertyStorage setProperty:bodyData forKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:(NSMutableURLRequest *)requestWithoutBody];

            // mark this as an upload request so future code knows to find the body via NSURLProtocol instead
            [requestWithoutBody sbt_markUploadTaskRequest];
        }
    }
    
    return [self swz_uploadTaskWithRequest:requestWithoutBody fromFile:fileURL];
}

- (NSURLSessionUploadTask *)swz_uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;
{
    // remove the body to avoid a CFNetwork warning
    NSURLRequest *requestWithoutBody = [request sbt_copyWithoutBody];

    if ([requestWithoutBody isKindOfClass:[NSMutableURLRequest class]] && bodyData) {
        [SBTRequestPropertyStorage setProperty:bodyData forKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:(NSMutableURLRequest *)requestWithoutBody];

        // mark this as an upload request so future code knows to find the body via NSURLProtocol instead
        [requestWithoutBody sbt_markUploadTaskRequest];
    }

    return [self swz_uploadTaskWithRequest:requestWithoutBody fromData:bodyData completionHandler:completionHandler];
}

- (NSURLSessionUploadTask *)swz_uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;
{    
    return [self swz_uploadTaskWithRequest:request fromFile:fileURL completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)swz_dataTaskWithRequest:(NSURLRequest *)request
{
    if ([request isKindOfClass:[NSMutableURLRequest class]] && request.HTTPBody) {
        [SBTRequestPropertyStorage setProperty:request.HTTPBody forKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:(NSMutableURLRequest *)request];
    }
    
    return [self swz_dataTaskWithRequest:request];
}

- (NSURLSessionDataTask *)swz_dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler
{
    if ([request isKindOfClass:[NSMutableURLRequest class]] && request.HTTPBody) {
        [SBTRequestPropertyStorage setProperty:request.HTTPBody forKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:(NSMutableURLRequest *)request];
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
