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

@interface SBTRequestMatch : NSObject<NSCoding>

@property (nullable, nonatomic, readonly) NSString *url;
@property (nullable, nonatomic, readonly) NSArray<NSString *> *query;
@property (nullable, nonatomic, readonly) NSString *method;

+ (nonnull instancetype)URL:(nonnull NSString *)url; // any request matching the specified regex on the request URL
+ (nonnull instancetype)URL:(nonnull NSString *)url query:(nonnull NSArray<NSString *> *)query; // same as above additionally matching the query (params in GET and DELETE, body in POST and PUT)
+ (nonnull instancetype)URL:(nonnull NSString *)url query:(nonnull NSArray<NSString *> *)query method:(nonnull NSString *)method; // same as above additionally matching the HTTP method
+ (nonnull instancetype)URL:(nonnull NSString *)url method:(nonnull NSString *)method; // any request matching the specified regex on the request URL and HTTP method

+ (nonnull instancetype)query:(nonnull NSArray<NSString *> *)query; // any request matching the specified regex on the query (params in GET and DELETE, body in POST and PUT)
+ (nonnull instancetype)query:(nonnull NSArray<NSString *> *)query method:(nonnull NSString *)method; // same as above additionally matching the HTTP method

+ (nonnull instancetype)method:(nonnull NSString *)method; // any request matching the HTTP method

@end

#endif
