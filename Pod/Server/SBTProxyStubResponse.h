// SBTProxyStubResponse.h
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

#import <Foundation/Foundation.h>

@interface SBTProxyStubResponse: NSObject<NSCoding>

+ (nonnull SBTProxyStubResponse *)responseWithData:(nonnull NSData *)data
                                           headers:(nonnull NSDictionary<NSString *, NSString *> *)headers
                                        statusCode:(NSUInteger)statusCode
                                      responseTime:(NSTimeInterval)responseTime;

@property (nonnull, nonatomic, strong, readonly) NSData *data;
@property (nonnull, nonatomic, strong, readonly) NSDictionary<NSString *, NSString *> *headers;
@property (nonatomic, assign, readonly) NSUInteger statusCode;
@property (nonatomic, assign, readonly) NSTimeInterval responseTime;

@end
