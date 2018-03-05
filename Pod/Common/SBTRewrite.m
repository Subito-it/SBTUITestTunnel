// SBTRewrite.m
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

#import "SBTRewrite.h"

#pragma mark - SBTRewriteReplacement

@interface SBTRewriteReplacement()

@property (nonatomic, strong) NSData *findData;
@property (nonatomic, strong) NSData *replaceData;

@end

@implementation SBTRewriteReplacement

- (id)initWithCoder:(NSCoder *)decoder
{
    NSData *findData = [decoder decodeObjectForKey:NSStringFromSelector(@selector(findData))];
    NSData *replaceData = [decoder decodeObjectForKey:NSStringFromSelector(@selector(replaceData))];
    
    NSString *find = [findData base64EncodedStringWithOptions:0];
    NSString *replace = [replaceData base64EncodedStringWithOptions:0];

    SBTRewriteReplacement *ret = [self initWithFind:find replace:replace];
    
    return ret;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.findData forKey:NSStringFromSelector(@selector(findData))];
    [encoder encodeObject:self.replaceData forKey:NSStringFromSelector(@selector(replaceData))];
}

- (nonnull instancetype)initWithFind:(nonnull NSString *)find replace:(nonnull NSString *)replace
{
    if ((self = [super init])) {
        self.findData = [find dataUsingEncoding:NSUTF8StringEncoding];
        self.replaceData = [replace dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    return self;
}

@end

#pragma mark - SBTRewrite

@interface SBTRewrite()

@property (nonatomic, strong) NSArray<SBTRewriteReplacement *> *requestReplacement;
@property (nonatomic, strong) NSArray<SBTRewriteReplacement *> *responseReplacement;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *requestHeaders;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *responseHeaders;
@property (nonatomic, assign) NSInteger returnCode;

@end

@implementation SBTRewrite

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
    NSArray<SBTRewriteReplacement *> *requestReplacement = [decoder decodeObjectForKey:NSStringFromSelector(@selector(requestReplacement))];
    NSArray<SBTRewriteReplacement *> *responseReplacement = [decoder decodeObjectForKey:NSStringFromSelector(@selector(responseReplacement))];
    NSDictionary<NSString *, NSString *> *requestHeaders = [decoder decodeObjectForKey:NSStringFromSelector(@selector(requestHeaders))];
    NSDictionary<NSString *, NSString *> *responseHeaders = [decoder decodeObjectForKey:NSStringFromSelector(@selector(responseHeaders))];
    NSInteger returnCode = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(returnCode))];

    return [self initWithResponseReplacement:responseReplacement requestReplacement:requestReplacement responseHeaders:responseHeaders requestHeaders:requestHeaders returnCode:returnCode];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.requestReplacement forKey:NSStringFromSelector(@selector(requestReplacement))];
    [encoder encodeObject:self.responseReplacement forKey:NSStringFromSelector(@selector(responseReplacement))];
    [encoder encodeObject:self.requestHeaders forKey:NSStringFromSelector(@selector(requestHeaders))];
    [encoder encodeObject:self.responseHeaders forKey:NSStringFromSelector(@selector(responseHeaders))];
    [encoder encodeInteger:self.returnCode forKey:NSStringFromSelector(@selector(returnCode))];
}

#pragma mark - Response

- (instancetype)initWithResponse:(NSArray<SBTRewriteReplacement *> *)replacement
                         headers:(NSDictionary<NSString *, NSString *> *)headers
                      returnCode:(NSInteger)returnCode
{
    return [self initWithResponseReplacement:replacement requestReplacement:nil responseHeaders:headers requestHeaders:nil returnCode:returnCode];
}

- (instancetype)initWithResponse:(NSArray<SBTRewriteReplacement *> *)replacement
                         headers:(NSDictionary<NSString *, NSString *> *)headers
{
    return [self initWithResponse:replacement headers:headers returnCode:0];
}

- (instancetype)initWithResponse:(NSArray<SBTRewriteReplacement *> *)replacement
{
    return [self initWithResponse:replacement headers:@{} returnCode:0];
}

#pragma mark - Request

- (instancetype)initWithRequest:(NSArray<SBTRewriteReplacement *> *)replacement
                        headers:(NSDictionary<NSString *, NSString *> *)headers
{
    return [self initWithResponseReplacement:nil requestReplacement:replacement responseHeaders:nil requestHeaders:headers returnCode:0];
}

- (instancetype)initWithRequest:(NSArray<SBTRewriteReplacement *> *)replacement
{
    return [self initWithRequest:replacement headers:@{}];
}

#pragma mark - Mixed

- (instancetype)initWithResponse:(NSArray<SBTRewriteReplacement *> *)replacement
                  requestHeaders:(NSDictionary<NSString *, NSString *> *)headers
{
    return [self initWithResponseReplacement:replacement requestReplacement:nil responseHeaders:nil requestHeaders:headers returnCode:0];
}

- (instancetype)initWithResponseReplacement:(NSArray<SBTRewriteReplacement *> *)responseReplacement
                         requestReplacement:(NSArray<SBTRewriteReplacement *> *)requestReplacement
                            responseHeaders:(NSDictionary<NSString *, NSString *> *)responseHeaders
                             requestHeaders:(NSDictionary<NSString *, NSString *> *)requestHeaders
                                 returnCode:(NSInteger)returnCode
{
    if ((self = [super init])) {
        self.responseReplacement = responseReplacement;
        self.requestReplacement = requestReplacement;
        
        self.responseHeaders = responseHeaders;
        self.requestHeaders = requestHeaders;
        
        self.returnCode = returnCode;
    }
    
    return self;
}

@end

#endif
