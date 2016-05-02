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

#import "NSURLSessionConfiguration+SBTUITestTunnel.h"
#import "SBTProxyURLProtocol.h"
#import <objc/runtime.h>

@implementation NSURLSessionConfiguration (SBTUITestTunnel)

typedef NSURLSessionConfiguration*(*SessionConfigConstructor)(id,SEL);
static SessionConfigConstructor orig_defaultSessionConfiguration;
static SessionConfigConstructor orig_ephemeralSessionConfiguration;

static SessionConfigConstructor SBTTestTunnelSwizzle(SEL selector, SessionConfigConstructor newImpl)
{
    Class cls = NSURLSessionConfiguration.class;
    Class metaClass = object_getClass(cls);
    
    Method origMethod = class_getClassMethod(cls, selector);
    SessionConfigConstructor origImpl = (SessionConfigConstructor)method_getImplementation(origMethod);
    if (!class_addMethod(metaClass, selector, (IMP)newImpl, method_getTypeEncoding(origMethod)))
    {
        method_setImplementation(origMethod, (IMP)newImpl);
    }
    return origImpl;
}

static NSURLSessionConfiguration* SBTTestTunnelStubs_defaultSessionConfiguration(id self, SEL _cmd)
{
    NSURLSessionConfiguration* config = orig_defaultSessionConfiguration(self,_cmd); // call original method
    [self addSBTProxyProtocol:config];
    
    return config;
}

static NSURLSessionConfiguration* SBTTestTunnelStubs_ephemeralSessionConfiguration(id self, SEL _cmd)
{
    NSURLSessionConfiguration* config = orig_ephemeralSessionConfiguration(self,_cmd); // call original method
    [self addSBTProxyProtocol:config];
    
    return config;
}

+ (void)addSBTProxyProtocol:(NSURLSessionConfiguration *)sessionConfig
{
    NSMutableArray * urlProtocolClasses = [sessionConfig.protocolClasses mutableCopy];
    [urlProtocolClasses insertObject:[SBTProxyURLProtocol class] atIndex:0];
    sessionConfig.protocolClasses = urlProtocolClasses;
}

+ (void)load
{
    orig_defaultSessionConfiguration = SBTTestTunnelSwizzle(@selector(defaultSessionConfiguration),
                                                            SBTTestTunnelStubs_defaultSessionConfiguration);
    orig_ephemeralSessionConfiguration = SBTTestTunnelSwizzle(@selector(ephemeralSessionConfiguration),
                                                              SBTTestTunnelStubs_ephemeralSessionConfiguration);
}

@end