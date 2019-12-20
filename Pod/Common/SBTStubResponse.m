// SBTStubResponse.m
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

#define IsEqualToString(x,y) ((x && [x isEqualToString:y]) || (!x && !y))
#define IsEqualToDictionary(x,y) ((x && [x isEqualToDictionary:y]) || (!x && !y))

#import "SBTStubResponse.h"
#import "NSString+SwiftDemangle.h"

#define defaultJsonMime @"application/json"
#define defaultXmlMime @"application/xml"
#define defaultTextMime @"text/plain"
#define defaultDataMime @"application/octet-stream"
#define defaultHtmlMime @"text/html"

static NSTimeInterval defaultResponseTime;
static NSInteger defaultReturnCode;
static NSString *defaultNSDictionaryContentType;
static NSString *defaultNSStringContentType;
static NSString *defaultNSDataContentType;

@implementation SBTStubResponse : NSObject

- (instancetype)copyWithZone:(NSZone *)zone
{
    SBTStubResponse *copy = [[[self class] allocWithZone:zone] init];

    if (copy) {
        [copy setData:[self.data copyWithZone:zone]];
        [copy setHeaders:[self.headers copyWithZone:zone]];
        [copy setContentType:[self.contentType copyWithZone:zone]];
        [copy setReturnCode:self.returnCode];
        [copy setResponseTime:self.responseTime];
        [copy setFailureCode:self.failureCode];
        [copy setActiveIterations:self.activeIterations];
    }

    return copy;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    NSData *data = [decoder decodeObjectForKey:NSStringFromSelector(@selector(data))];
    NSDictionary<NSString *, NSString *> *headers = [decoder decodeObjectForKey:NSStringFromSelector(@selector(headers))];
    NSString *contentType = [decoder decodeObjectForKey:NSStringFromSelector(@selector(contentType))];
    NSInteger returnCode = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(returnCode))];
    NSTimeInterval responseTime = [decoder decodeDoubleForKey:NSStringFromSelector(@selector(responseTime))];
    NSInteger failureCode = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(failureCode))];
    NSInteger activeIterations = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(activeIterations))];
    
    SBTStubResponse *ret = [self initWithResponse:data headers:headers contentType:contentType returnCode:returnCode responseTime:responseTime activeIterations:activeIterations];
    ret.failureCode = failureCode;
    return ret;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.data forKey:NSStringFromSelector(@selector(data))];
    [encoder encodeObject:self.headers forKey:NSStringFromSelector(@selector(headers))];
    [encoder encodeObject:self.contentType forKey:NSStringFromSelector(@selector(contentType))];
    [encoder encodeInteger:self.returnCode forKey:NSStringFromSelector(@selector(returnCode))];
    [encoder encodeDouble:self.responseTime forKey:NSStringFromSelector(@selector(responseTime))];
    [encoder encodeInteger:self.failureCode forKey:NSStringFromSelector(@selector(failureCode))];
    [encoder encodeInteger:self.activeIterations forKey:NSStringFromSelector(@selector(activeIterations))];
}

- (instancetype)initWithResponse:(id)response headers:(NSDictionary<NSString *, NSString *> *)headers contentType:(NSString *)contentType returnCode:(NSInteger)returnCode responseTime:(NSTimeInterval)responseTime activeIterations:(NSInteger)activeIterations
{
    if ((self = [super init])) {
        _contentType = contentType;
        if (!_contentType) {
            if ([response isKindOfClass:[NSData class]]) {
                _contentType = defaultNSDataContentType;
            } else if ([response isKindOfClass:[NSString class]]) {
                _contentType = defaultNSStringContentType;
            } else if ([response isKindOfClass:[NSDictionary class]]) {
                _contentType = defaultNSDictionaryContentType;
            }
        }
        
        NSAssert(_contentType, @"Missing contentType");

        if ([response isKindOfClass:[NSData class]]) {
            _data = (NSData *)response;
        } else if ([response isKindOfClass:[NSString class]]) {
            _data = [(NSString *)response dataUsingEncoding:NSUTF8StringEncoding];
        } else if ([response isKindOfClass:[NSDictionary class]] && [_contentType isEqualToString:defaultJsonMime]) {
            NSError *error;
            _data = [NSJSONSerialization dataWithJSONObject:(NSDictionary *)response
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];
            
            NSAssert(!error && _data, @"Failed to convert dictionary to json!");
        }
        
        NSAssert(_data, @"Unhandled data");
        
        NSMutableDictionary *mHeaders = [headers mutableCopy] ?: [NSMutableDictionary dictionary];
        mHeaders[@"Content-Type"] = _contentType;
        
        _headers = mHeaders;
        _returnCode = returnCode;
        _responseTime = responseTime;
        _activeIterations = activeIterations;
    }
    
    return self;
}

- (instancetype)initWithFileNamed:(NSString *)filename headers:(NSDictionary<NSString *, NSString *> *)headers returnCode:(NSInteger)returnCode responseTime:(NSTimeInterval)responseTime activeIterations:(NSInteger)activeIterations
{
    NSString *name = [filename stringByDeletingPathExtension];
    NSString *extension = [filename pathExtension];
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:name ofType:extension]];
    
    // try in current test bundle
    if (!data) {
        for (NSBundle *bundle in [NSBundle allBundles]) {
            if ([bundle.bundlePath hasSuffix:@".xctest"]) {
                data = [NSData dataWithContentsOfFile:[bundle pathForResource:name ofType:extension]];
                if (data) {
                    break;
                }
            }
        }
    }
    
    NSAssert(data, @"No data in file");

    NSString *contentType = nil;
    if ([extension isEqualToString:@"json"]) {
        contentType = defaultJsonMime;
    } else if ([extension isEqualToString:@"xml"]) {
        contentType = defaultXmlMime;
    } else if ([extension isEqualToString:@"txt"]) {
        contentType = defaultTextMime;
    } else if ([extension containsString:@"htm"]) {
        contentType = defaultHtmlMime;
    }
    
    NSAssert(contentType, @"Unknown file extension!");
    
    return [self initWithResponse:data headers:headers contentType:contentType returnCode:returnCode responseTime:responseTime activeIterations:activeIterations];
}

+ (void)initialize
{
    [self resetUnspecifiedDefaults];
}

+ (instancetype)failureWithCustomErrorCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime activeIterations:(NSInteger)activeIterations
{
    SBTStubResponse *ret = [[SBTStubResponse alloc] initWithResponse:@"" headers:nil contentType:nil returnCode:defaultReturnCode responseTime:responseTime activeIterations:activeIterations];
    ret.failureCode = code;

    return ret;
}

#pragma mark - NSObject protocol

- (BOOL)isEqual:(SBTStubResponse *)other
{
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        return
            [self.data isEqual:other.data] &&
            IsEqualToDictionary(self.headers, other.headers);
            IsEqualToString(self.contentType, other.contentType) &&
            self.returnCode == other.returnCode &&
            self.responseTime == other.responseTime &&
            self.failureCode == other.failureCode;
    }
}

- (NSUInteger)hash
{
    return [self.data hash] ^ [self.headers hash] ^ [self.contentType hash] ^ self.returnCode ^ [@(self.responseTime) hash] ^ self.failureCode;
}

#pragma mark - Default overriders

+ (NSTimeInterval)defaultResponseTime
{
    return defaultResponseTime;
}

+ (void)setDefaultResponseTime:(NSTimeInterval)responseTime
{
    defaultResponseTime = responseTime;
}

+ (NSInteger)defaultReturnCode
{
    return defaultReturnCode;
}

+ (void)setDefaultReturnCode:(NSInteger)returnCode
{
    defaultReturnCode = returnCode;
}

+ (NSString *)defaultDictionaryContentType
{
    return defaultNSDictionaryContentType;
}

+ (void)setDefaultDictionaryContentType:(NSString *)contentType
{
    defaultNSDictionaryContentType = contentType;
}

+ (NSString *)defaultDataContentType
{
    return defaultNSDataContentType;
}

+ (void)setDefaultDataContentType:(NSString *)contentType
{
    defaultNSDataContentType = contentType;
}

+ (NSString *)defaultStringContentType
{
    return defaultNSStringContentType;
}

+ (void)setDefaultStringContentType:(NSString *)contentType
{
    defaultNSStringContentType = contentType;
}

+ (void)resetUnspecifiedDefaults
{
    defaultResponseTime = 0.0;
    defaultReturnCode = 200;
    defaultNSDictionaryContentType = defaultJsonMime;
    defaultNSStringContentType = defaultTextMime;
    defaultNSDataContentType = defaultDataMime;
}

@end

#endif
