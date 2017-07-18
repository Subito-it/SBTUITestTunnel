// SBTRequestMatch.m
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

#import "SBTRequestMatch.h"

@interface SBTRequestMatch()

@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSArray<NSString *> *query;
@property (nonatomic, strong) NSString *method;

@end

@implementation SBTRequestMatch : NSObject

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.url = [decoder decodeObjectForKey:NSStringFromSelector(@selector(url))];
        self.query = [decoder decodeObjectForKey:NSStringFromSelector(@selector(query))];
        self.method = [decoder decodeObjectForKey:NSStringFromSelector(@selector(method))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.url forKey:NSStringFromSelector(@selector(url))];
    [encoder encodeObject:self.query forKey:NSStringFromSelector(@selector(query))];
    [encoder encodeObject:self.method forKey:NSStringFromSelector(@selector(method))];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"URL: %@\nQuery: %@\nMethod: %@", self.url ?: @"N/A", self.query ?: @"N/A", self.method ?: @"N/A"];
}

- (nonnull instancetype)initWithURL:(NSString *)url
{
    if ((self = [super init])) {
        _url = url;
    }
    
    return self;
}

- (nonnull instancetype)initWithURL:(NSString *)url query:(NSArray<NSString *> *)query
{
    if ((self = [self initWithURL:url])) {
        _query = query;
    }
    
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (nonnull instancetype)initWithURL:(NSString *)url query:(NSArray<NSString *> *)query method:(NSString *)method
{
    if ((self = [self initWithURL:url query:query])) {
        _method = method;
    }
    
    return self;
}

- (nonnull instancetype)initWithURL:(NSString *)url method:(NSString *)method
{
    return [self initWithURL:url query:nil method:method];
}

- (nonnull instancetype)initWithQuery:(NSArray<NSString *> *)query
{
    return [self initWithURL:nil query:query method:nil];
}

- (nonnull instancetype)initWithQuery:(NSArray<NSString *> *)query method:(NSString *)method
{
    return [self initWithURL:nil query:query method:method];
}

- (nonnull instancetype)initWithMethod:(NSString *)method
{
    return [self initWithURL:nil query:nil method:method];
}

#pragma clang diagnostic pop

@end

#endif

