// NSURLRequest+HTTPBodyFix.m
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

#import "include/NSURLRequest+HTTPBodyFix.h"
#import "include/SBTUITestTunnel.h"
#import "include/SBTSwizzleHelpers.h"
#import "include/SBTRequestPropertyStorage.h"

@interface NSURLRequest (SBTUITestTunnelOriginals)
- (NSData *)sbt_originalHTTPBody;
- (id)sbt_originalCopyWithZone:(NSZone *)zone NS_RETURNS_RETAINED;
- (id)sbt_originalMutableCopyWithZone:(NSZone *)zone NS_RETURNS_RETAINED;
@end

@implementation NSURLRequest (HTTPBodyFix)

// In Xcode 15+ CFNetwork emits a runtime warning when an upload task contains a body:
//
//     The request of a upload task should not contain a body or a body stream, use `upload(for:fromFile:)`,
//     `upload(for:from:)`, or supply the body stream through the `urlSession(_:needNewBodyStreamForTask:)`
//     delegate method.
//
// To work around this, we keep track of requests originating from upload tasks by swizzling in
// `NSURLSession+HTTPBodyFix`.  For those tasks, we save the original body via NSURLProtocol and remove it
// from the request to avoid the warning.
//
// When using a request body (e.g., when matching stubs), previously marked upload requests _must_ exclusively
// reference the copy from NSURLProtocol because the request's `HTTPBody` was cleared.

NSString * const SBTUITunneledNSURLProtocolIsUploadTaskKey = @"SBTUITunneledNSURLProtocolIsUploadTaskKey";

+ (NSData *)sbt_readFromBodyStream:(NSInputStream *)stream
{
    if (!stream) {
        return nil;
    }

    NSMutableData *data = [NSMutableData data];
    uint8_t buffer[4096];

    BOOL shouldClose = (stream.streamStatus == NSStreamStatusNotOpen);
    if (shouldClose) {
        [stream open];
    }

    @try {
        NSInteger bytesRead;
        while ((bytesRead = [stream read:buffer maxLength:sizeof(buffer)]) > 0) {
            [data appendBytes:buffer length:bytesRead];
        }
        if (bytesRead < 0) {
            return nil;
        }
    } @finally {
        if (shouldClose) {
            [stream close];
        }
    }

    return data.length > 0 ? data : nil;
}

- (NSData *)sbt_uploadHTTPBody
{
    // First try getting from property storage (existing behavior)
    NSData *bodyData = [SBTRequestPropertyStorage propertyForKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:self];
    
    // If no stored data, try direct HTTPBody
    if (!bodyData) {
        bodyData = [self HTTPBody];
    }
    
    // If still no data, try reading from stream
    if (!bodyData && [self HTTPBodyStream]) {
        bodyData = [NSURLRequest sbt_readFromBodyStream:[self HTTPBodyStream]];
    }
    
    return bodyData;
}

- (BOOL)sbt_isUploadTaskRequest
{
    return ([SBTRequestPropertyStorage propertyForKey:SBTUITunneledNSURLProtocolIsUploadTaskKey inRequest:self] != nil);
}

- (void)sbt_markUploadTaskRequest
{
    NSAssert([self isKindOfClass:[NSMutableURLRequest class]], @"Attempted to mark an immutable request as an upload");

    if ([self isKindOfClass:[NSMutableURLRequest class]]) {
        [SBTRequestPropertyStorage setProperty:@YES forKey:SBTUITunneledNSURLProtocolIsUploadTaskKey inRequest:(NSMutableURLRequest *)self];
    }
}

- (NSURLRequest *)sbt_copyWithoutBody
{
    NSMutableURLRequest *modifiedRequest = [self mutableCopy];

    // clear the body and assume callers are providing that data elsewhere
    modifiedRequest.HTTPBody = nil;
    modifiedRequest.HTTPBodyStream = nil;

    // retain the original mutability
    if ([self isKindOfClass:[NSMutableURLRequest class]]) {
        return modifiedRequest;
    } else {
        return [modifiedRequest copy];
    }
}

// MARK: -

- (NSData *)swz_HTTPBody
{
    // upload tasks will trigger a runtime warning if their body is non-nil, see note above
    if ([self sbt_isUploadTaskRequest]) {
        return nil;
    }

    NSData *ret = [self sbt_originalHTTPBody];
        
    return ret ?: [SBTRequestPropertyStorage propertyForKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:self];
}

- (id)swz_copyWithZone:(NSZone *)zone NS_RETURNS_RETAINED
{
    NSURLRequest *ret = [self sbt_originalCopyWithZone:zone];
    
    if ([ret isKindOfClass:[NSMutableURLRequest class]]) {
        NSData *body = [SBTRequestPropertyStorage propertyForKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:self];
        if (body) {
            [SBTRequestPropertyStorage setProperty:body forKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:(NSMutableURLRequest *)ret];
        }
    }
    
    return ret;
}

- (id)swz_mutableCopyWithZone:(NSZone *)zone NS_RETURNS_RETAINED
{
    NSMutableURLRequest *ret = [self sbt_originalMutableCopyWithZone:zone];
    
    if ([ret isKindOfClass:[NSMutableURLRequest class]]) {
        NSData *body = [SBTRequestPropertyStorage propertyForKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:self];
        if (body) {
            [SBTRequestPropertyStorage setProperty:body forKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:(NSMutableURLRequest *)ret];
        }
    }
    
    return ret;
}

+ (void)sbt_installHTTPBodySwizzles
{
    SBTTestTunnelInstanceSwizzleOnce(NSURLRequest.class, @selector(HTTPBody), @selector(swz_HTTPBody), @selector(sbt_originalHTTPBody));
    SBTTestTunnelInstanceSwizzleOnce(NSURLRequest.class, @selector(copyWithZone:), @selector(swz_copyWithZone:), @selector(sbt_originalCopyWithZone:));
    SBTTestTunnelInstanceSwizzleOnce(NSURLRequest.class, @selector(mutableCopyWithZone:), @selector(swz_mutableCopyWithZone:), @selector(sbt_originalMutableCopyWithZone:));
}

- (nullable NSData *)sbt_extractHTTPBody
{
    if ([self HTTPBody]) {
        return [self HTTPBody];
    } else if ([self HTTPBodyStream]) {
        return [NSURLRequest sbt_readFromBodyStream:[self HTTPBodyStream]];
    } else if ([self sbt_isUploadTaskRequest]) {
        return [self sbt_uploadHTTPBody];
    }
    return nil;
}

@end
