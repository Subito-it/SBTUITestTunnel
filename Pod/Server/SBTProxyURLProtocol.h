// SBTProxyURLProtocol.h
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

#import <Foundation/Foundation.h>
#import "SBTRequestMatch.h"

@class SBTProxyStubResponse;

@interface SBTProxyURLProtocol : NSURLProtocol

+ (nullable NSString *)proxyRequestsMatching:(nonnull SBTRequestMatch *)match delayResponse:(NSTimeInterval)delayResponseTime responseBlock:(nullable void(^)(NSURLRequest * __nullable, NSURLRequest * __nullable, NSHTTPURLResponse * __nullable , NSData * __nullable, NSTimeInterval))block;

+ (BOOL)proxyRequestsRemoveWithId:(nonnull NSString *)reqId;
+ (void)proxyRequestsRemoveAll;

+ (nullable NSString *)stubRequestsMatching:(nonnull SBTRequestMatch *)match stubResponse:(nonnull SBTProxyStubResponse *)stubResponse didStubRequest:(nullable void(^)(NSURLRequest * __nullable))block;

+ (BOOL)stubRequestsRemoveWithId:(nonnull NSString *)reqId;
+ (void)stubRequestsRemoveAll;

@end

#endif
