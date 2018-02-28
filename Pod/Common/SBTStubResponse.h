// SBTStubResponse.h
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

@interface SBTStubResponse : NSObject<NSCoding>

- (nonnull id)init NS_UNAVAILABLE;

/**
 *  Initializer
 *
 *  @param code an NSError Codes
 *  @param responseTime the response time in seconds of the stubbed response
 */
+ (nonnull instancetype)failureWithCustomErrorCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime;

/**
 *  Initializer
 *
 *  @param response an instance of NSDictionary, NSData, NSString that represents the data to be returned
 *  @param headers a dictionary that represents the response headers
 *  @param contentType the return content type
 *  @param returnCode the HTTP return code of the stubbed response
 *  @param responseTime the response time in seconds of the stubbed response
 */
- (nonnull instancetype)initWithResponse:(nonnull id)response
                                 headers:(nonnull NSDictionary<NSString *, NSString *> *)headers
                             contentType:(nonnull NSString *)contentType
                              returnCode:(NSInteger)returnCode
                            responseTime:(NSTimeInterval)responseTime NS_DESIGNATED_INITIALIZER;

#pragma mark - Convenience initializers

/**
 *  Initializer
 *
 *  Note that parameters not specified in the initializer have default values
 *
 *  @param response an instance of NSDictionary, NSData, NSString that represents the data to be returned
 *
 *  contentType will be automatically assigned based on the response instance type, unless it gets overridden by the default setter methods
 *  - NSDictionary: application/json
 *  - NSData: application/octet-stream
 *  - NSString: text/plain
 *
 *  returnCode will be 200, unless it gets overridden by the default setter methods
 *  responseTime will be 0, unless it gets overridden by the default setter methods
 */
- (nonnull instancetype)initWithResponse:(nonnull id)response;

/**
 *  Initializer
 *
 *  Note that parameters not specified in the initializer have default values
 *
 *  @param response an instance of NSDictionary, NSData, NSString that represents the data to be returned
 *  @param responseTime the response time in seconds of the stubbed response
 *
 *  contentType will be automatically assigned based on the response instance type, unless it gets overridden by the default setter methods
 *  - NSDictionary: application/json
 *  - NSData: application/octet-stream
 *  - NSString: text/plain
 *
 *  returnCode will be 200, unless it gets overridden by the default setter methods
 */
- (nonnull instancetype)initWithResponse:(nonnull id)response responseTime:(NSTimeInterval)responseTime;

/**
 *  Initializer
 *
 *  Note that parameters not specified in the initializer have default values
 *
 *  @param response an instance of NSDictionary, NSData, NSString that represents the data to be returned
 *  @param returnCode the HTTP return code of the stubbed response
 *
 *  contentType will be automatically assigned based on the response instance type, unless it gets overridden by the default setter methods
 *  - NSDictionary: application/json
 *  - NSData: application/octet-stream
 *  - NSString: text/plain
 *
 *  responseTime will be 0, unless it gets overridden by the default setter methods
 */
- (nonnull instancetype)initWithResponse:(nonnull id)response returnCode:(NSInteger)returnCode;

/**
 *  Initializer
 *
 *  Note that parameters not specified in the initializer have default values
 *
 *  @param response an instance of NSDictionary, NSData, NSString that represents the data to be returned
 *  @param returnCode the HTTP return code of the stubbed response
 *  @param responseTime the response time in seconds of the stubbed response
 *
 *  contentType will be automatically assigned based on the response instance type, unless it gets overridden by the default setter methods
 *  - NSDictionary: application/json
 *  - NSData: application/octet-stream
 *  - NSString: text/plain
 */
- (nonnull instancetype)initWithResponse:(nonnull id)response returnCode:(NSInteger)returnCode responseTime:(NSTimeInterval)responseTime;

/**
 *  Initializer
 *
 *  @param response an instance of NSDictionary, NSData, NSString that represents the data to be returned
 *  @param contentType the return content type
 *  @param returnCode the HTTP return code of the stubbed response
 *
 *  responseTime will be 0, unless it gets overridden by the default setter methods
 */
- (nonnull instancetype)initWithResponse:(nonnull id)response contentType:(nonnull NSString *)contentType returnCode:(NSInteger)returnCode;

/**
 *  Initializer
 *
 *  @param response an instance of NSDictionary, NSData, NSString that represents the data to be returned
 *  @param headers a dictionary that represents the response headers
 *  @param returnCode the HTTP return code of the stubbed response
 *  @param responseTime the response time in seconds of the stubbed response
 */
- (nonnull instancetype)initWithResponse:(nonnull id)response headers:(nullable NSDictionary<NSString *, NSString *> *)headers returnCode:(NSInteger)returnCode responseTime:(NSTimeInterval)responseTime;

/**
 *  Initializer
 *
 *  @param filename the file name with the content to be used for stubbing
 *
 *  contentType will be automatically assigned based on file extension
 *  - .json: application/json
 *  - .xml: application/xml
 *  - .htm*: text/html
 *  - .txt: text/plain
 *
 *  returnCode will be 200, unless it gets overridden by the default setter methods
 *  responseTime will be 0, unless it gets overridden by the default setter methods
 */
- (nonnull instancetype)initWithFileNamed:(nonnull NSString *)filename;

/**
 *  Initializer
 *
 *  @param filename the file name with the content to be used for stubbing
 *  @param responseTime the response time in seconds of the stubbed response
 *
 *  contentType will be automatically assigned based on file extension
 *  - .json: application/json
 *  - .xml: application/xml
 *  - .htm*: text/html
 *  - .txt: text/plain
 *
 *  returnCode will be 200, unless it gets overridden by the default setter methods
 */
- (nonnull instancetype)initWithFileNamed:(nonnull NSString *)filename responseTime:(NSTimeInterval)responseTime;

/**
 *  Initializer
 *
 *  @param filename the file name with the content to be used for stubbing
 *  @param returnCode the HTTP return code of the stubbed response
 *
 *  contentType will be automatically assigned based on file extension
 *  - .json: application/json
 *  - .xml: application/xml
 *  - .htm*: text/html
 *  - .txt: text/plain
 *
 *  responseTime will be 0, unless it gets overridden by the default setter methods
 */
- (nonnull instancetype)initWithFileNamed:(nonnull NSString *)filename returnCode:(NSInteger)returnCode;

/**
 *  Initializer
 *
 *  @param filename the file name with the content to be used for stubbing
 *  @param returnCode the HTTP return code of the stubbed response
 *  @param responseTime the response time in seconds of the stubbed response
 *
 *  contentType will be automatically assigned based on file extension
 *  - .json: application/json
 *  - .xml: application/xml
 *  - .htm*: text/html
 *  - .txt: text/plain
 */
- (nonnull instancetype)initWithFileNamed:(nonnull NSString *)filename returnCode:(NSInteger)returnCode responseTime:(NSTimeInterval)responseTime;

/**
 *  Initializer
 *
 *  @param filename the file name with the content to be used for stubbing
 *  @param headers a dictionary that represents the response headers
 *  @param returnCode the HTTP return code of the stubbed response
 *  @param responseTime the response time in seconds of the stubbed response
 *
 *  contentType will be automatically assigned based on file extension
 *  - .json: application/json
 *  - .xml: application/xml
 *  - .htm*: text/html
 *  - .txt: text/plain
 */
- (nonnull instancetype)initWithFileNamed:(nonnull NSString *)filename headers:(nullable NSDictionary<NSString *, NSString *> *)headers returnCode:(NSInteger)returnCode responseTime:(NSTimeInterval)responseTime;

#pragma mark - Accessors

@property (nonatomic, readonly, nonnull) NSData *data;
@property (nonatomic, readonly, nonnull) NSString *contentType;
@property (nonatomic, readonly, nonnull) NSDictionary *headers;
@property (nonatomic, readonly) NSInteger returnCode;
@property (nonatomic, readonly) NSTimeInterval responseTime;
@property (nonatomic, readonly) NSInteger failureCode;

#pragma mark - Default overriders

/**
 *  Set the default response time for all SBTStubResponses when not specified in intializer
 *
 *  @param responseTime the response time in seconds of the stubbed response
 */
+ (void)setDefaultResponseTime:(NSTimeInterval)responseTime;

/**
 *  Set the default return code for all SBTStubResponses when not specified in intializer
 *
 *  @param returnCode the HTTP return code of the stubbed response
 */
+ (void)setDefaultReturnCode:(NSInteger)returnCode;

/**
 *  Set the default Content-Type to be used when passing NSDictionary's as responses
 *
 *  @param contentType the returned contentType
 */
+ (void)setDictionaryDefaultContentType:(nonnull NSString *)contentType;

/**
 *  Set the default Content-Type to be used when passing NSData as responses
 *
 *  @param contentType the returned contentType
 */
+ (void)setDataDefaultContentType:(nonnull NSString *)contentType;

/**
 *  Set the default Content-Type to be used when passing NSString's as responses
 *
 *  @param contentType the returned contentType
 */
+ (void)setStringDefaultContentType:(nonnull NSString *)contentType;

/**
 *  Reset defaults values of responseTime, returnCode and contentTypes
 */
+ (void)resetUnspecifiedDefaults;

@end

#endif
