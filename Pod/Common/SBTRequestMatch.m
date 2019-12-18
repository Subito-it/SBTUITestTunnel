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
#import "NSData+SHA1.h"

@interface SBTRequestMatch()

@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSArray<NSString *> *query;
@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *requestHeaders;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *responseHeaders;

@end

@implementation SBTRequestMatch : NSObject

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.url = [decoder decodeObjectForKey:NSStringFromSelector(@selector(url))];
        self.query = [decoder decodeObjectForKey:NSStringFromSelector(@selector(query))];
        self.method = [decoder decodeObjectForKey:NSStringFromSelector(@selector(method))];
        self.body = [decoder decodeObjectForKey:NSStringFromSelector(@selector(body))];
        self.requestHeaders = [decoder decodeObjectForKey:NSStringFromSelector(@selector(requestHeaders))];
        self.responseHeaders = [decoder decodeObjectForKey:NSStringFromSelector(@selector(responseHeaders))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.url forKey:NSStringFromSelector(@selector(url))];
    [encoder encodeObject:self.query forKey:NSStringFromSelector(@selector(query))];
    [encoder encodeObject:self.method forKey:NSStringFromSelector(@selector(method))];
    [encoder encodeObject:self.body forKey:NSStringFromSelector(@selector(body))];
    [encoder encodeObject:self.requestHeaders forKey:NSStringFromSelector(@selector(requestHeaders))];
    [encoder encodeObject:self.responseHeaders forKey:NSStringFromSelector(@selector(responseHeaders))];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"URL: %@\nQuery: %@\nMethod: %@\nBody: %@\nRequest headers: %@\nResponse headers: %@", self.url ?: @"N/A", self.query ?: @"N/A", self.method ?: @"N/A", self.body ?: @"N/A", self.requestHeaders ?: @"N/A", self.responseHeaders ?: @"N/A"];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (instancetype)initWithURL:(NSString *)url query:(NSArray<NSString *> *)query method:(NSString *)method body:(NSString *)body requestHeaders:(NSDictionary<NSString *, NSString *> *)requestHeaders responseHeaders:(NSDictionary<NSString *, NSString *> *)responseHeaders
{
    if ((self = [super init])) {
        _url = url;
        _query = query;
        _method = method;
        _body = body;
        _requestHeaders = requestHeaders;
        _responseHeaders = responseHeaders;
    }
    
    return self;
}

- (instancetype)initWithURL:(NSString *)url
{
    return [self initWithURL:url query:nil method:nil body:nil requestHeaders:nil responseHeaders:nil];
}

- (instancetype)initWithURL:(NSString *)url query:(NSArray<NSString *> *)query
{
    return [self initWithURL:url query:query method:nil body:nil requestHeaders:nil responseHeaders:nil];
}

- (instancetype)initWithURL:(NSString *)url query:(NSArray<NSString *> *)query method:(NSString *)method body:(NSString *)body
{
    return [self initWithURL:url query:query method:method body:body requestHeaders:nil responseHeaders:nil];
}

- (instancetype)initWithURL:(NSString *)url query:(NSArray<NSString *> *)query method:(NSString *)method
{
    return [self initWithURL:url query:query method:method body:nil requestHeaders:nil responseHeaders:nil];
}

- (instancetype)initWithURL:(NSString *)url method:(NSString *)method
{
    return [self initWithURL:url query:nil method:method body:nil requestHeaders:nil responseHeaders:nil];
}

- (instancetype)initWithQuery:(NSArray<NSString *> *)query
{
    return [self initWithURL:nil query:query method:nil body:nil requestHeaders:nil responseHeaders:nil];
}

- (instancetype)initWithQuery:(NSArray<NSString *> *)query method:(NSString *)method
{
    return [self initWithURL:nil query:query method:method body:nil requestHeaders:nil responseHeaders:nil];
}

- (instancetype)initWithMethod:(NSString *)method
{
    return [self initWithURL:nil query:nil method:method body:nil requestHeaders:nil responseHeaders:nil];
}

- (instancetype)initWithURL:(NSString *)url requestHeaders:(NSDictionary<NSString *, NSString *> *)requestHeaders
{
    return [self initWithURL:url query:nil method:nil body:nil requestHeaders:requestHeaders responseHeaders:nil];
}

- (instancetype)initWithURL:(NSString *)url responseHeaders:(NSDictionary<NSString *, NSString *> *)responseHeaders
{
    return [self initWithURL:url query:nil method:nil body:nil requestHeaders:nil responseHeaders:responseHeaders];
}

- (instancetype)initWithURL:(NSString *)url requestHeaders:(NSDictionary<NSString *, NSString *> *)requestHeaders responseHeaders:(NSDictionary<NSString *, NSString *> *)responseHeaders
{
    return [self initWithURL:url query:nil method:nil body:nil requestHeaders:requestHeaders responseHeaders:responseHeaders];
}

#pragma clang diagnostic pop

- (NSString *)identifier
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    
    return [data SHA1];
}

@end

#endif

