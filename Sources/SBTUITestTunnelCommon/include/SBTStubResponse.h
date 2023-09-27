// SBTStubResponse.h
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

@interface SBTStubResponse: NSObject<NSSecureCoding, NSCopying>

/// Set the default response time for all SBTStubResponses when not specified in intializer. If positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
@property (class, nonatomic, assign) NSTimeInterval defaultResponseTime;

/// Set the default return code for all SBTStubResponses when not specified in intializer
@property (class, nonatomic, assign) NSInteger defaultReturnCode;

/// Set the default Content-Type to be used when passing NSDictionary's as responses
@property (class, nonnull, nonatomic, strong) NSString *defaultDictionaryContentType;

/// Set the default Content-Type to be used when passing NSData's as responses
@property (class, nonnull, nonatomic, strong) NSString *defaultDataContentType;

/// Set the default Content-Type to be used when passing NSString's as responses
@property (class, nonnull, nonatomic, strong) NSString *defaultStringContentType;

@property (nullable, nonatomic, strong) NSData *data;
@property (nullable, nonatomic, strong) NSString *contentType;

/// A dictionary that represents the response headers
@property (nullable, nonatomic, strong) NSDictionary<NSString *, NSString *> *headers;

/// The HTTP return code of the stubbed response
@property (nonatomic, assign) NSInteger returnCode;

/// If positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
@property (nonatomic, assign) NSTimeInterval responseTime;

/// The number of times the stubbing will be performed
@property (nonatomic, assign) NSInteger activeIterations;

/**
 *  Initializer
 *
 *  @param response an instance of NSDictionary, NSData, NSString that represents the data to be returned
 *  @param headers a dictionary that represents the response headers
 *  @param contentType the content type of the response.
 *                     If the value of this parameter is not `nil`, then the content type will be set to the value provided.
 *                     On the other hand, if this parameter is `nil` and `Content-Type` is provided in `headers`, then the value provided in `headers` will be used.
 *                     The content type will be determined automatically using the type of `response` otherwise.
 *  @param returnCode the HTTP return code of the stubbed response
 *  @param responseTime if positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
 *  @param activeIterations the number of times the stubbing will be performed
 */
- (nonnull instancetype)initWithResponse:(nonnull NSObject *)response
                                 headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                             contentType:(nullable NSString *)contentType
                              returnCode:(NSInteger)returnCode
                            responseTime:(NSTimeInterval)responseTime
                        activeIterations:(NSInteger)activeIterations NS_SWIFT_NAME(init(_response:_headers:_contentType:_returnCode:_responseTime:_activeIterations:));

/**
 *  Initializer
 *
 *  @param fileNamed the file name with the content to be used for stubbing
 *  @param headers a dictionary that represents the response headers
 *  @param returnCode the HTTP return code of the stubbed response
 *  @param responseTime if positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
 *  @param activeIterations the number of times the stubbing will be performed
 *
 *  contentType will be automatically assigned based on file extension
 *  - .json: application/json
 *  - .xml: application/xml
 *  - .htm*: text/html
 *  - .txt: text/plain
 *  - .pdf application/pdf
 */
- (nonnull instancetype)initWithFileNamed:(nonnull NSString *)fileNamed
                                  headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                               returnCode:(NSInteger)returnCode
                             responseTime:(NSTimeInterval)responseTime
                         activeIterations:(NSInteger)activeIterations NS_SWIFT_NAME(init(_fileNamed:_headers:_returnCode:_responseTime:_activeIterations:));

/// Reset defaults values of responseTime, returnCode and contentTypes
+ (void)resetUnspecifiedDefaults;

@end
