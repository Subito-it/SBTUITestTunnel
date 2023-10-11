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

#import "private/NSURLRequest+HTTPBodyFix.h"
#import "include/SBTUITestTunnel.h"
#import "include/SBTSwizzleHelpers.h"

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

- (NSData *)sbt_uploadHTTPBody
{
    return [NSURLProtocol propertyForKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:self];
}

- (BOOL)sbt_isUploadTaskRequest
{
    return ([NSURLProtocol propertyForKey:SBTUITunneledNSURLProtocolIsUploadTaskKey inRequest:self] != nil);
}

- (void)sbt_markUploadTaskRequest
{
    NSAssert([self isKindOfClass:[NSMutableURLRequest class]], @"Attempted to mark an immutable request as an upload");

    if ([self isKindOfClass:[NSMutableURLRequest class]]) {
        [NSURLProtocol setProperty:@YES forKey:SBTUITunneledNSURLProtocolIsUploadTaskKey inRequest:(NSMutableURLRequest *)self];
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

    NSData *ret = [self swz_HTTPBody];
        
    return ret ?: [NSURLProtocol propertyForKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:self];
}

- (id)swz_copyWithZone:(NSZone *)zone
{
    NSURLRequest *ret = [self swz_copyWithZone:zone];
    
    if ([ret isKindOfClass:[NSMutableURLRequest class]]) {
        NSData *body = [NSURLProtocol propertyForKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:self];
        if (body) {
            [NSURLProtocol setProperty:body forKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:(NSMutableURLRequest *)ret];            
        }
    }
    
    return ret;
}

- (id)swz_mutableCopyWithZone:(NSZone *)zone
{
    NSMutableURLRequest *ret = [self swz_mutableCopyWithZone:zone];
    
    if ([ret isKindOfClass:[NSMutableURLRequest class]]) {
        NSData *body = [NSURLProtocol propertyForKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:self];
        if (body) {
            [NSURLProtocol setProperty:body forKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:(NSMutableURLRequest *)ret];
        }
    }
    
    return ret;
}

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SBTTestTunnelInstanceSwizzle(self.class, @selector(HTTPBody), @selector(swz_HTTPBody));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(copyWithZone:), @selector(swz_copyWithZone:));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(mutableCopyWithZone:), @selector(swz_mutableCopyWithZone:));
    });
}

@end
