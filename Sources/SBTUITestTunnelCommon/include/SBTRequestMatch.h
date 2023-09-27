// SBTRequestMatch.h
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

@interface SBTRequestMatch: NSObject<NSSecureCoding, NSCopying>

/// A regex that is matched against the request url
@property (nullable, nonatomic, strong) NSString *url;

/// An array of a regex that are matched against the request query (params in GET and DELETE, body in POST and PUT). Instance will match if all regex are fulfilled. You can specify that a certain query should not match by prefixing it with an exclamation mark `!`
@property (nullable, nonatomic, strong) NSArray<NSString *> *query;

/// HTTP method
@property (nullable, nonatomic, strong) NSString *method;

/// A regex that is matched against the request body
@property (nullable, nonatomic, strong) NSString *body;

/// A regex that is matched against request headers
@property (nullable, nonatomic, strong) NSDictionary<NSString *, NSString *> *requestHeaders;

/// A regex that is matched against response headers
@property (nullable, nonatomic, strong) NSDictionary<NSString *, NSString *> *responseHeaders;

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
- (nonnull instancetype)initWithURL:(nullable NSString *)url
                              query:(nullable NSArray<NSString *> *)query
                             method:(nullable NSString *)method
                               body:(nullable NSString *)body
                     requestHeaders:(nullable NSDictionary<NSString *, NSString *> *)requestHeaders
                    responseHeaders:(nullable NSDictionary<NSString *, NSString *> *)responseHeaders NS_SWIFT_NAME(init(_url:_query:_method:_body:_requestHeaders:_responseHeaders:));

- (BOOL)matchesURLRequest:(nullable NSURLRequest *)request;

- (BOOL)matchesRequestHeaders:(nullable NSDictionary<NSString *, NSString *> *)requestHeaders;

- (BOOL)matchesResponseHeaders:(nullable NSDictionary<NSString *, NSString *> *)responseHeaders;

@end
