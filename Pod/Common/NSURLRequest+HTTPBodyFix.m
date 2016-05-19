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

#import "NSURLRequest+HTTPBodyFix.h"
#import "SBTUITestTunnel.h"
#import "SBTSwizzleHelpers.h"

@implementation NSURLRequest (HTTPBodyFix)

- (NSData *)swz_HTTPBody
{
    NSData *ret = [self swz_HTTPBody];
    
    return ret ?: [NSURLProtocol propertyForKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:self];
}

- (id)swz_copyWithZone:(NSZone *)zone
{
    NSURLRequest *ret = [self swz_copyWithZone:zone];
    NSData *body = [NSURLProtocol propertyForKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:self];
    [NSURLProtocol setProperty:body forKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:ret];
    
    return ret;
}

- (id)swz_mutableCopyWithZone:(NSZone *)zone
{
    NSMutableURLRequest *ret = [self swz_mutableCopyWithZone:zone];
    NSData *body = [NSURLProtocol propertyForKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:self];
    [NSURLProtocol setProperty:body forKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:ret];
    
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
