// SBTRewrite.h
//
// Copyright (C) 2021 Subito.it S.r.l (www.subito.it)
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

@class SBTRewriteReplacement;

@interface SBTRewrite: NSObject<NSSecureCoding>

@property (nonnull, nonatomic, strong) NSArray<SBTRewriteReplacement *> *urlReplacement;
@property (nonnull, nonatomic, strong) NSArray<SBTRewriteReplacement *> *requestReplacement;
@property (nonnull, nonatomic, strong) NSArray<SBTRewriteReplacement *> *responseReplacement;

@property (nonnull, nonatomic, strong) NSDictionary<NSString *, NSString *> *requestHeadersReplacement;
@property (nonnull, nonatomic, strong) NSDictionary<NSString *, NSString *> *responseHeadersReplacement;

@property (nonatomic, assign) NSInteger responseStatusCode;
@property (nonatomic, assign) NSInteger activeIterations;

/**
 *  Initializer
 *
 *  @param urlReplacement an array or SBTRewriteReplacement objects that will perform replacements on the request URL (host + query)
 *  @param requestReplacement an array or SBTRewriteReplacement objects that will perform replacements on the request body
 *  @param responseReplacement an array or SBTRewriteReplacement objects that will perform replacements on the response body
 *  @param requestHeadersReplacement a dictionary that represents the request headers. Keys not present will be added while existing keys will be replaced. If the value is empty the key will be removed
 *  @param responseHeadersReplacement a dictionary that represents the response headers. Keys not present will be added while existing keys will be replaced. If the value is empty the key will be removed
 *  @param responseStatusCode the response HTTP code to return
 *  @param activeIterations the number of times the rewrite will be performed
 */
- (nonnull instancetype)initWithUrlReplacement:(nonnull NSArray<SBTRewriteReplacement *> *)urlReplacement
                            requestReplacement:(nonnull NSArray<SBTRewriteReplacement *> *)requestReplacement
                           responseReplacement:(nonnull NSArray<SBTRewriteReplacement *> *)responseReplacement
                     requestHeadersReplacement:(nonnull NSDictionary<NSString *, NSString *> *)requestHeadersReplacement
                    responseHeadersReplacement:(nonnull NSDictionary<NSString *, NSString *> *)responseHeadersReplacement
                            responseStatusCode:(NSInteger)responseStatusCode
                              activeIterations:(NSInteger)activeIterations NS_SWIFT_NAME(init(_urlReplacement:_requestReplacement:_responseReplacement:_requestHeadersReplacement:_responseHeadersReplacement:_responseStatusCode:_activeIterations:));

- (nonnull instancetype) __unavailable init;

/**
 *  Process a url by applying replacement specified in initializer
 *
 *  @param url url to replace
 */
- (nonnull NSURL *)rewriteUrl:(nonnull NSURL *)url;

/**
 *  Process a dictionary of request headers by applying replacement specified in initializer
 *
 *  @param requestHeaders request headers to replace
 */
- (nonnull NSDictionary<NSString *, NSString *> *)rewriteRequestHeaders:(nonnull NSDictionary<NSString *, NSString *> *)requestHeaders;

/**
 *  Process a dictionary of response headers by applying replacement specified in initializer
 *
 *  @param responseHeaders response headers to replace
 */
- (nonnull NSDictionary<NSString *, NSString *> *)rewriteResponseHeaders:(nonnull NSDictionary<NSString *, NSString *> *)responseHeaders;

/**
 *  Process a request body by applying replacement specified in initializer
 *
 *  @param requestBody request body
 */
- (nonnull NSData *)rewriteRequestBody:(nonnull NSData *)requestBody;

/**
 *  Process a response body by applying replacement specified in initializer
 *
 *  @param responseBody response body
 */
- (nonnull NSData *)rewriteResponseBody:(nonnull NSData *)responseBody;

/**
 *  Process a status code by applying replacement specified in initializer
 *
 *  @param statusCode the status code
 */
- (NSInteger)rewriteStatusCode:(NSInteger)statusCode;

@end
