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

#import <Foundation/Foundation.h>

@interface SBTProxyURLProtocol : NSURLProtocol

+ (nullable NSString *)proxyRequestsWithRegex:(nonnull NSString *)regexPattern delayResponse:(NSTimeInterval)delayResponseTime responseBlock:(nullable void(^)(NSURLRequest * __nullable, NSURLRequest * __nullable, NSHTTPURLResponse * __nullable , NSData * __nullable, NSTimeInterval))block;
+ (nullable NSString *)proxyRequestsWithQueryParams:(nonnull NSArray<NSString *> *)queryParams delayResponse:(NSTimeInterval)delayResponseTime responseBlock:(nullable void(^)(NSURLRequest * __nullable, NSURLRequest * __nullable, NSHTTPURLResponse * __nullable , NSData * __nullable, NSTimeInterval))block;

+ (BOOL)proxyRequestsRemoveWithId:(nonnull NSString *)reqId;
+ (void)proxyRequestsRemoveAll;

@end
