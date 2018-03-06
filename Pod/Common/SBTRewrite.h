// SBTRewrite.h
//
// Copyright (C) 2018 Subito.it S.r.l (www.subito.it)
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

@interface SBTRewriteReplacement : NSObject<NSCoding>

- (nonnull id)init NS_UNAVAILABLE;

/**
 *  Initializer
 *
 *  @param find a string regex that search for a string
 *  @param replace a string that replaces the string matched by find
 */
- (nonnull instancetype)initWithFind:(nonnull NSString *)find replace:(nonnull NSString *)replace;

/**
 *  Process a string by applying replacement specified in initializer
 *
 *  @param string string to replace
 */
- (nonnull NSString *)replace:(nonnull NSString *)string;

@end

@interface SBTRewrite : NSObject<NSCoding>

- (nonnull id)init NS_UNAVAILABLE;

#pragma mark - Response

/**
 *  Initializer
 *
 *  @param responseReplacement an array or SBTRewriteReplacement objects that will perform replacements on the response body
 *  @param responseHeadersReplacement a dictionary that represents the response headers. Keys not present will be added while existing keys will be replaced. If the value is empty the key will be removed
 *  @param responseCode the response HTTP code to return
 */
- (nonnull instancetype)initWithResponseReplacement:(nonnull NSArray<SBTRewriteReplacement *> *)responseReplacement
                                 headersReplacement:(nonnull NSDictionary<NSString *, NSString *> *)responseHeadersReplacement
                                         responseCode:(NSInteger)responseCode;

/**
 *  Initializer
 *
 *  @param responseReplacement an array or SBTRewriteReplacement objects that will perform replacements on the response body
 *  @param responseHeadersReplacement a dictionary that represents the response headers. Keys not present will be added while existing keys will be replaced. If the value is empty the key will be removed
 */
- (nonnull instancetype)initWithResponseReplacement:(nonnull NSArray<SBTRewriteReplacement *> *)responseReplacement
                                 headersReplacement:(nonnull NSDictionary<NSString *, NSString *> *)responseHeadersReplacement;

/**
 *  Initializer
 *
 *  @param responseReplacement an array or SBTRewriteReplacement objects that will perform replacements on the response body
 */
- (nonnull instancetype)initWithResponseReplacement:(nonnull NSArray<SBTRewriteReplacement *> *)responseReplacement;

/**
 *  Initializer
 *
 *  @param responseHeadersReplacement a dictionary that represents the response headers. Keys not present will be added while existing keys will be replaced. If the value is empty the key will be removed
 */
- (nonnull instancetype)initWithResponseHeadersReplacement:(nonnull NSDictionary<NSString *, NSString *> *)responseHeadersReplacement;

/**
 *  Initializer
 *
 *  @param statusCode the response status code to rewrite
 */
- (nonnull instancetype)initWithResponseStatusCode:(NSInteger)statusCode;

#pragma mark - Request

/**
 *  Initializer
 *
 *  @param requestReplacement an array or SBTRewriteReplacement objects that will perform replacements on the request body
 *  @param requestHeadersReplacement a dictionary that represents the request headers. Keys not present will be added while existing keys will be replaced. If the value is empty the key will be removed
 */
- (nonnull instancetype)initWithRequestReplacement:(nonnull NSArray<SBTRewriteReplacement *> *)requestReplacement
                         requestHeadersReplacement:(nonnull NSDictionary<NSString *, NSString *> *)requestHeadersReplacement;

/**
 *  Initializer
 *
 *  @param requestReplacement an array or SBTRewriteReplacement objects that will perform replacements on the request body
 */
- (nonnull instancetype)initWithRequestReplacement:(nonnull NSArray<SBTRewriteReplacement *> *)requestReplacement;

/**
 *  Initializer
 *
 *  @param requestHeadersReplacement a dictionary that represents the request headers. Keys not present will be added while existing keys will be replaced. If the value is empty the key will be removed
 */
- (nonnull instancetype)initWithRequestHeadersReplacement:(nonnull NSDictionary<NSString *, NSString *> *)requestHeadersReplacement;

#pragma mark - URL

/**
 *  Initializer
 *
 *  @param urlReplacement an array or SBTRewriteReplacement objects that will perform replacements on the request URL (host + query)
 */
- (nonnull instancetype)initWithRequestUrlReplacement:(nonnull NSArray<SBTRewriteReplacement *> *)urlReplacement;

#pragma mark - Designated

/**
 *  Initializer
 *
 *  @param urlReplacement an array or SBTRewriteReplacement objects that will perform replacements on the request URL (host + query)
 *  @param responseReplacement an array or SBTRewriteReplacement objects that will perform replacements on the response body
 *  @param responseHeadersReplacement a dictionary that represents the response headers. Keys not present will be added while existing keys will be replaced. If the value is empty the key will be removed
 *  @param requestReplacement an array or SBTRewriteReplacement objects that will perform replacements on the request body
 *  @param requestHeadersReplacement a dictionary that represents the request headers. Keys not present will be added while existing keys will be replaced. If the value is empty the key will be removed
 *  @param responseCode the response HTTP code to return
 */
- (nonnull instancetype)initWithUrlReplacement:(nullable NSArray<SBTRewriteReplacement *> *)urlReplacement
                            requestReplacement:(nullable NSArray<SBTRewriteReplacement *> *)requestReplacement
                     requestHeadersReplacement:(nullable NSDictionary<NSString *, NSString *> *)requestHeadersReplacement
                           responseReplacement:(nullable NSArray<SBTRewriteReplacement *> *)responseReplacement
                    responseHeadersReplacement:(nullable NSDictionary<NSString *, NSString *> *)responseHeadersReplacement
                                  responseCode:(NSInteger)responseCode NS_DESIGNATED_INITIALIZER;

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
- (nonnull NSDictionary *)rewriteRequestHeaders:(nonnull NSDictionary *)requestHeaders;

/**
 *  Process a dictionary of response headers by applying replacement specified in initializer
 *
 *  @param responseHeaders response headers to replace
 */
- (nonnull NSDictionary *)rewriteResponseHeaders:(nonnull NSDictionary *)responseHeaders;

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

#endif
