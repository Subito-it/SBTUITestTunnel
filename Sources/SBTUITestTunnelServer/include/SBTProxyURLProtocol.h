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

@import Foundation;

@class SBTRewrite;
@class SBTRequestMatch;
@class SBTStubResponse;
@class SBTMonitoredNetworkRequest;
@class SBTActiveStub;

@interface SBTProxyURLProtocol : NSURLProtocol

+ (void)reset;

#pragma mark - Throttle Requests

+ (nullable NSString *)throttleRequestsMatching:(nonnull SBTRequestMatch *)match delayResponse:(NSTimeInterval)delayResponseTime;
+ (BOOL)throttleRequestsRemoveWithId:(nonnull NSString *)reqId;
+ (void)throttleRequestsRemoveAll;

#pragma mark - Monitored Requests

+ (nullable NSString *)monitorRequestsMatching:(nonnull SBTRequestMatch *)match;
+ (BOOL)monitorRequestsRemoveWithId:(nonnull NSString *)reqId;
+ (void)monitorRequestsRemoveAll;
+ (nullable NSArray<SBTMonitoredNetworkRequest *> *)monitoredRequestsAll;
+ (void)monitoredRequestsFlushAll;

#pragma mark - Stubbing Requests

+ (nullable NSString *)stubRequestsMatching:(nonnull SBTRequestMatch *)match stubResponse:(nonnull SBTStubResponse *)stubResponse;
+ (BOOL)stubRequestsRemoveWithId:(nonnull NSString *)reqId;
+ (BOOL)stubRequestsRemoveWithRequestMatch:(nonnull SBTRequestMatch *)match;
+ (void)stubRequestsRemoveAll;
+ (nonnull NSArray<SBTActiveStub *> *)stubRequestsAll;

#pragma mark - Rewrite Requests

+ (nullable NSString *)rewriteRequestsMatching:(nonnull SBTRequestMatch *)match rewrite:(nonnull SBTRewrite *)rewrite;
+ (BOOL)rewriteRequestsRemoveWithId:(nonnull NSString *)reqId;
+ (void)rewriteRequestsRemoveAll;

#pragma mark - Cookie Block Requests

+ (nullable NSString *)cookieBlockRequestsMatching:(nonnull SBTRequestMatch *)match activeIterations:(NSInteger)activeIterations;
+ (BOOL)cookieBlockRequestsRemoveWithId:(nonnull NSString *)reqId;
+ (void)cookieBlockRequestsRemoveAll;

@end
