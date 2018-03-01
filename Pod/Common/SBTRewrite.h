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

@end

@interface SBTRewrite : NSObject<NSCoding>

- (nonnull id)init NS_UNAVAILABLE;

#pragma mark - Response

/**
 *  Initializer
 *
 *  @param replacement an array or SBTRewriteReplacement objects that will perform replacements on the response body
 *  @param headers a dictionary that represents the response headers. Keys not present in response will be added while existing keys will be replaced. If the value contains an exclamation mark `!` the key will be removed
 *  @param returnCode the HTTP return code of the rewritten response
 */
- (nonnull instancetype)initWithResponse:(nonnull NSArray<SBTRewriteReplacement *> *)replacement
                                 headers:(nonnull NSDictionary<NSString *, NSString *> *)headers
                              returnCode:(NSInteger)returnCode NS_DESIGNATED_INITIALIZER;

/**
 *  Initializer
 *
 *  @param replacement an array or SBTRewriteReplacement objects that will perform replacements on the response body
 *  @param headers a dictionary that represents the response headers. Keys not present in response will be added while existing keys will be replaced. If the value contains an exclamation mark `!` the key will be removed
 */
- (nonnull instancetype)initWithResponse:(nonnull NSArray<SBTRewriteReplacement *> *)replacement
                                 headers:(nonnull NSDictionary<NSString *, NSString *> *)headers;

/**
 *  Initializer
 *
 *  @param replacement an array or SBTRewriteReplacement objects that will perform replacements on the response body
 */
- (nonnull instancetype)initWithResponse:(nonnull NSArray<SBTRewriteReplacement *> *)replacement;

#pragma mark - Request

/**
 *  Initializer
 *
 *  @param replacement an array or SBTRewriteReplacement objects that will perform replacements on the request body
 *  @param headers a dictionary that represents the request headers
 */
- (nonnull instancetype)initWithRequest:(nonnull NSArray<SBTRewriteReplacement *> *)replacement
                                headers:(nonnull NSDictionary<NSString *, NSString *> *)headers NS_DESIGNATED_INITIALIZER;

/**
 *  Initializer
 *
 *  @param replacement an array or SBTRewriteReplacement objects that will perform replacements on the request body
 */
- (nonnull instancetype)initWithRequest:(nonnull NSArray<SBTRewriteReplacement *> *)replacement;

@end

#endif
