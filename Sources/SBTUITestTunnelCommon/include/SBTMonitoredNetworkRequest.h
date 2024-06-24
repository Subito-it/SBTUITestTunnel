// SBTMonitoredNetworkRequest.h
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

@class SBTRequestMatch;

@interface SBTMonitoredNetworkRequest : NSObject<NSSecureCoding>

- (nullable NSString *)responseString;
- (nullable id)responseJSON;

- (nullable NSString *)requestString;
- (nullable id)requestJSON;

- (BOOL)matches:(nonnull SBTRequestMatch *)match;

@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, assign) NSTimeInterval requestTime;

@property (nullable, nonatomic, strong) NSURLRequest *request;
@property (nullable, nonatomic, strong) NSURLRequest *originalRequest;
@property (nullable, nonatomic, strong) NSHTTPURLResponse *response;

@property (nullable, nonatomic, strong) NSData *responseData;
@property (nullable, nonatomic, strong) NSData *requestData;

@property (nonatomic, assign) BOOL isStubbed;
@property (nonatomic, assign) BOOL isRewritten;

@end
