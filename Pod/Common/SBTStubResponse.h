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

@interface SBTStubResponse : NSObject<NSCoding, NSCopying>

/**
 *  Initializer
 *
 *  @param response an instance of NSDictionary, NSData, NSString that represents the data to be returned
 *  @param headers a dictionary that represents the response headers
 *  @param contentType the return content type
 *  @param returnCode the HTTP return code of the stubbed response
 *  @param responseTime the response time in seconds of the stubbed response
 *  @param activeIterations the number of times the stub will be applied
*/
- (nonnull instancetype)initWithResponse:(nonnull id)response headers:(nullable NSDictionary<NSString *, NSString *> *)headers contentType:(nullable NSString *)contentType returnCode:(NSInteger)returnCode responseTime:(NSTimeInterval)responseTime activeIterations:(NSInteger)activeIterations NS_REFINED_FOR_SWIFT;

/**
 *  Initializer
 *
 *  @param filename the file name with the content to be used for stubbing
 *  @param headers a dictionary that represents the response headers
 *  @param returnCode the HTTP return code of the stubbed response
 *  @param responseTime the response time in seconds of the stubbed response
 *  @param activeIterations the number of times the stub will be applied
 *
 *  contentType will be automatically assigned based on file extension
 *  - .json: application/json
 *  - .xml: application/xml
 *  - .htm*: text/html
 *  - .txt: text/plain
*/
- (nonnull instancetype)initWithFileNamed:(nonnull NSString *)filename headers:(nullable NSDictionary<NSString *, NSString *> *)headers returnCode:(NSInteger)returnCode responseTime:(NSTimeInterval)responseTime activeIterations:(NSInteger)activeIterations NS_REFINED_FOR_SWIFT;

/**
 *  Initializer
 *
 *  @param code an NSError Codes
 *  @param responseTime the response time in seconds of the stubbed response
 *  @param activeIterations the number of times the stub will be applied
 */
+ (nonnull instancetype)failureWithCustomErrorCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime activeIterations:(NSInteger)activeIterations;

#pragma mark - Accessors

/**
 *  Set the default response time for all SBTStubResponses when not specified in intializer
*/
@property (class, nonatomic, assign) NSTimeInterval defaultResponseTime;

/**
 *  Set the default return code for all SBTStubResponses when not specified in intializer
*/
@property (class, nonatomic, assign) NSInteger defaultReturnCode;

/**
 *  Set the default Content-Type to be used when passing NSDictionary's as responses
*/
@property (class, nonatomic, strong, nonnull) NSString *defaultDictionaryContentType;

/**
 *  Set the default Content-Type to be used when passing NSData's as responses
*/
@property (class, nonatomic, strong, nonnull) NSString *defaultDataContentType;

/**
 *  Set the default Content-Type to be used when passing NSString's as responses
*/
@property (class, nonatomic, strong, nonnull) NSString *defaultStringContentType;

@property (nonatomic, strong, nonnull) NSData *data;
@property (nonatomic, strong, nonnull) NSString *contentType;
@property (nonatomic, strong, nonnull) NSDictionary *headers;
@property (nonatomic, assign) NSInteger returnCode;
@property (nonatomic, assign) NSTimeInterval responseTime;
@property (nonatomic, assign) NSInteger failureCode;
@property (nonatomic, assign) NSInteger activeIterations;

#pragma mark - Default overriders

/**
 *  Reset defaults values of responseTime, returnCode and contentTypes
 */
+ (void)resetUnspecifiedDefaults;

@end

#endif
