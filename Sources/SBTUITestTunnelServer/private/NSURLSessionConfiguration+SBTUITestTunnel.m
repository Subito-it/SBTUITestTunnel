// NSURLSessionConfiguration+SBTUITestTunnel.m
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

// https://github.com/AliSoftware/OHHTTPStubs/blob/master/OHHTTPStubs/Sources/NSURLSession/OHHTTPStubs%2BNSURLSessionConfiguration.m

@import SBTUITestTunnelCommon;

#import "NSURLSessionConfiguration+SBTUITestTunnel.h"
#import "../include/SBTProxyURLProtocol.h"

@interface NSURLSessionConfiguration (SBTUITestTunnelOriginals)
+ (NSURLSessionConfiguration *)sbt_originalDefaultSessionConfiguration;
+ (NSURLSessionConfiguration *)sbt_originalEphemeralSessionConfiguration;
@end

@implementation NSURLSessionConfiguration (SBTUITestTunnel)

+ (NSURLSessionConfiguration *)swz_defaultSessionConfiguration
{
    NSURLSessionConfiguration *config = [self sbt_originalDefaultSessionConfiguration];
    [self addSBTProxyProtocol:config];
    
    return config;
}

+ (NSURLSessionConfiguration *)swz_ephemeralSessionConfiguration
{
    NSURLSessionConfiguration *config = [self sbt_originalEphemeralSessionConfiguration];
    [self addSBTProxyProtocol:config];
    
    return config;
}

+ (void)addSBTProxyProtocol:(NSURLSessionConfiguration *)sessionConfig
{
    NSMutableArray * urlProtocolClasses = [sessionConfig.protocolClasses mutableCopy];
    [urlProtocolClasses insertObject:[SBTProxyURLProtocol class] atIndex:0];
    sessionConfig.protocolClasses = urlProtocolClasses;
}

+ (void)sbt_installSessionConfigurationSwizzles
{
    SBTTestTunnelClassSwizzleOnce(NSURLSessionConfiguration.class, @selector(defaultSessionConfiguration), @selector(swz_defaultSessionConfiguration), @selector(sbt_originalDefaultSessionConfiguration));
    SBTTestTunnelClassSwizzleOnce(NSURLSessionConfiguration.class, @selector(ephemeralSessionConfiguration), @selector(swz_ephemeralSessionConfiguration), @selector(sbt_originalEphemeralSessionConfiguration));
}

@end
