// SBTRequestMatch.h
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

@interface SBTRequestMatch : NSObject<NSCoding, NSCopying>

@property (nullable, nonatomic, readonly) NSString *url;
@property (nullable, nonatomic, readonly) NSArray<NSString *> *query;
@property (nullable, nonatomic, readonly) NSString *method;
@property (nullable, nonatomic, readonly) NSString *body;
@property (nullable, nonatomic, readonly) NSDictionary<NSString *, NSString *> *requestHeaders;
@property (nullable, nonatomic, readonly) NSDictionary<NSString *, NSString *> *responseHeaders;
@property (nullable, nonatomic, readonly) NSString *identifier;

/**
    Note:
    Given that parameter order isn't guaranteed it is recommended to specify the `query` parameter in the `SBTRequestMatch`'s initializer
*/

/**
 *  Initializer
 *
 *  @param url a regex that is matched against the request url
 *  @param query an array of a regex that are matched against the request query (params in GET and DELETE, body in POST and PUT). Instance will match if all regex are fulfilled. You can specify that a certain query should not match by prefixing it with an exclamation mark `!`
 *  @param method HTTP method
 *  @param body a regex that is matched against the request body
 *  @param requestHeaders a regex that is matched against request headers
 *  @param responseHeaders a regex that is matched against response headers
 */
- (nonnull instancetype)initWithURL:(nonnull NSString *)url query:(nonnull NSArray<NSString *> *)query method:(nonnull NSString *)method body:(nonnull NSString *)body requestHeaders:(nonnull NSDictionary<NSString *, NSString *> *)requestHeaders responseHeaders:(nonnull NSDictionary<NSString *, NSString *> *)responseHeaders;

/**
 *  Initializer
 *
 *  @param url a regex that is matched against the request url
 *  @param query an array of a regex that are matched against the request query (params in GET and DELETE, body in POST and PUT). Instance will match if all regex are fulfilled. You can specify that a certain query should not match by prefixing it with an exclamation mark `!`
 *  @param method HTTP method
 *  @param body a regex that is matched against the request body
 */
- (nonnull instancetype)initWithURL:(nonnull NSString *)url query:(nonnull NSArray<NSString *> *)query method:(nonnull NSString *)method body:(nonnull NSString *)body;

/**
 *  Initializer
 *
 *  @param url a regex that is matched against the request url
 *  @param query an array of a regex that are matched against the request query (params in GET and DELETE, body in POST and PUT). Instance will match if all regex are fulfilled. You can specify that a certain query should not match by prefixing it with an exclamation mark `!`
 *  @param method HTTP method
 */
- (nonnull instancetype)initWithURL:(nonnull NSString *)url query:(nonnull NSArray<NSString *> *)query method:(nonnull NSString *)method;

/**
 *  Initializer
 *
 *  @param url a regex that is matched against the request url
 *  @param method HTTP method
 */
- (nonnull instancetype)initWithURL:(nonnull NSString *)url method:(nonnull NSString *)method;

/**
 *  Initializer
 *
 *  @param url a regex that is matched against the request url
 *  @param query an array of a regex that are matched against the request query (params in GET and DELETE, body in POST and PUT). Instance will match if all regex are fulfilled. You can specify that a certain query should not match by prefixing it with an exclamation mark `!`
 */
- (nonnull instancetype)initWithURL:(nonnull NSString *)url query:(nonnull NSArray<NSString *> *)query;

/**
 *  Initializer
 *
 *  @param url a regex that is matched against the request url
 *  @param requestHeaders a regex that is matched against request headers
 */
- (nonnull instancetype)initWithURL:(nonnull NSString *)url requestHeaders:(nonnull NSDictionary<NSString *, NSString *> *)requestHeaders;

/**
 *  Initializer
 *
 *  @param url a regex that is matched against the request url
 *  @param responseHeaders a regex that is matched against response headers
 */
- (nonnull instancetype)initWithURL:(nonnull NSString *)url responseHeaders:(nonnull NSDictionary<NSString *, NSString *> *)responseHeaders;

/**
 *  Initializer
 *
 *  @param url a regex that is matched against the request url
 *  @param requestHeaders a regex that is matched against request headers
 *  @param responseHeaders a regex that is matched against response headers
 */
- (nonnull instancetype)initWithURL:(nonnull NSString *)url requestHeaders:(nonnull NSDictionary<NSString *, NSString *> *)requestHeaders responseHeaders:(nonnull NSDictionary<NSString *, NSString *> *)responseHeaders;

/**
 *  Initializer
 *
 *  @param url a regex that is matched against the request url
 */
- (nonnull instancetype)initWithURL:(nonnull NSString *)url;

/**
 *  Initializer
 *
 *  @param query an array of a regex that are matched against the request query (params in GET and DELETE, body in POST and PUT). Instance will match if all regex are fulfilled. You can specify that a certain query should not match by prefixing it with an exclamation mark `!`
 */
- (nonnull instancetype)initWithQuery:(nonnull NSArray<NSString *> *)query;

/**
 *  Initializer
 *
 *  @param query an array of a regex that are matched against the request query (params in GET and DELETE, body in POST and PUT). Instance will match if all regex are fulfilled. You can specify that a certain query should not match by prefixing it with an exclamation mark `!`
 *  @param method HTTP method
 */
- (nonnull instancetype)initWithQuery:(nonnull NSArray<NSString *> *)query method:(nonnull NSString *)method;

/**
 *  Initializer
 *
 *  @param method HTTP method
 */
- (nonnull instancetype)initWithMethod:(nonnull NSString *)method;

@end

#endif
