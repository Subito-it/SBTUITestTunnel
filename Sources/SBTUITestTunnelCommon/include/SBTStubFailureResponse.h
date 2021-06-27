// SBTStubFailureResponse.h
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

// Alternative approach to fix this: https://github.com/AliSoftware/OHHTTPStubs/pull/166

@import Foundation;

#import "SBTStubResponse.h"

@interface SBTStubFailureResponse: SBTStubResponse

/// The connection error failure code that will be used to when stubbing the URLConnectionDidFail NSError
@property (nonatomic, assign) NSInteger failureCode;

/**
 *  Initializer
 *
 *  @param failureCode the error code to be stubbed
 *  @param responseTime if positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
 *  @param activeIterations the number of times the stubbing will be performed
 */
- (nonnull instancetype)initWithFailureCode:(NSInteger)failureCode
                               responseTime:(NSTimeInterval)responseTime
                           activeIterations:(NSInteger)activeIterations NS_SWIFT_NAME(init(_errorCode:_responseTime:_activeInterations:));

@end
