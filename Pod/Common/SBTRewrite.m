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

@property (nonatomic, strong) NSArray<SBTRewriteReplacement *> *replacement;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *headers;
@property (nonatomic, assign) NSInteger returnCode;
@property (nonatomic, assign) BOOL isRequestRewrite;

@end

@implementation SBTRewrite

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
    NSArray<SBTRewriteReplacement *> *replacement = [decoder decodeObjectForKey:NSStringFromSelector(@selector(replacement))];
    NSDictionary<NSString *, NSString *> *headers = [decoder decodeObjectForKey:NSStringFromSelector(@selector(headers))];
    NSInteger returnCode = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(returnCode))];
    BOOL isRequestRewrite = [decoder decodeBoolForKey:NSStringFromSelector(@selector(isRequestRewrite))];

    SBTRewrite *ret;
    if (isRequestRewrite) {
        ret = [self initWithResponse:replacement headers:headers returnCode:returnCode];
    } else {
        ret = [self initWithRequest:replacement headers:headers];
    }

    return ret;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.replacement forKey:NSStringFromSelector(@selector(replacement))];
    [encoder encodeObject:self.headers forKey:NSStringFromSelector(@selector(headers))];
    [encoder encodeInteger:self.returnCode forKey:NSStringFromSelector(@selector(returnCode))];
    [encoder encodeBool:self.isRequestRewrite forKey:NSStringFromSelector(@selector(isRequestRewrite))];
}

#pragma mark - Response

- (instancetype)initWithResponse:(NSArray<SBTRewriteReplacement *> *)replacement
                         headers:(NSDictionary<NSString *, NSString *> *)headers
                      returnCode:(NSInteger)returnCode
{
    if ((self = [super init])) {
        self.replacement = replacement;
        self.headers = headers;
        self.returnCode = returnCode;
        self.isRequestRewrite = NO;
    }
    
    return self;
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
    if ((self = [super init])) {
        self.replacement = replacement;
        self.headers = headers;
        self.returnCode = 0;
        self.isRequestRewrite = YES;
    }
    
    return self;
}

- (instancetype)initWithRequest:(NSArray<SBTRewriteReplacement *> *)replacement
{
    return [self initWithRequest:replacement headers:@{}];
}

@end

#endif
