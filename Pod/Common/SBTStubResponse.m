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

@interface SBTStubResponse()

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *headers;
@property (nonatomic, strong) NSString *contentType;
@property (nonatomic, assign) NSInteger returnCode;
@property (nonatomic, assign) NSTimeInterval responseTime;

@end

@implementation SBTStubResponse : NSObject

+ (void)initialize
{
    [self resetUnspecifiedDefaults];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    NSData *data = [decoder decodeObjectForKey:NSStringFromSelector(@selector(data))];
    NSDictionary<NSString *, NSString *> *headers = [decoder decodeObjectForKey:NSStringFromSelector(@selector(headers))];
    NSString *contentType = [decoder decodeObjectForKey:NSStringFromSelector(@selector(contentType))];
    NSInteger returnCode = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(returnCode))];
    NSTimeInterval responseTime = [decoder decodeDoubleForKey:NSStringFromSelector(@selector(responseTime))];
    
    return [self initWithResponse:data headers:headers contentType:contentType returnCode:returnCode responseTime:responseTime];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.data forKey:NSStringFromSelector(@selector(data))];
    [encoder encodeObject:self.headers forKey:NSStringFromSelector(@selector(headers))];
    [encoder encodeObject:self.contentType forKey:NSStringFromSelector(@selector(contentType))];
    [encoder encodeInteger:self.returnCode forKey:NSStringFromSelector(@selector(returnCode))];
    [encoder encodeDouble:self.responseTime forKey:NSStringFromSelector(@selector(responseTime))];
}

- (instancetype)initWithResponse:(id)response
                         headers:(NSDictionary<NSString *, NSString *> *)headers
                     contentType:(NSString *)contentType
                      returnCode:(NSInteger)returnCode
                    responseTime:(NSTimeInterval)responseTime
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
        
        _headers = headers ?: @{};
        _returnCode = returnCode;
        _responseTime = responseTime;
    }
    
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (instancetype)initWithResponse:(id)response;
{
    return [self initWithResponse:response headers:nil contentType:nil returnCode:defaultReturnCode responseTime:defaultResponseTime];
}

- (instancetype)initWithResponse:(id)response returnCode:(NSInteger)returnCode;
{
    return [self initWithResponse:response headers:nil contentType:nil returnCode:returnCode responseTime:defaultResponseTime];
}

- (instancetype)initWithResponse:(id)response responseTime:(NSTimeInterval)responseTime
{
    return [self initWithResponse:response headers:nil contentType:nil returnCode:defaultReturnCode responseTime:responseTime];
}

- (instancetype)initWithResponse:(id)response returnCode:(NSInteger)returnCode responseTime:(NSTimeInterval)responseTime
{
    return [self initWithResponse:response headers:nil contentType:nil returnCode:returnCode responseTime:responseTime];
}

- (instancetype)initWithResponse:(id)response contentType:(NSString *)contentType returnCode:(NSInteger)returnCode
{
    return [self initWithResponse:response headers:nil contentType:contentType returnCode:returnCode responseTime:defaultResponseTime];
}

- (instancetype)initWithResponse:(id)response headers:(NSDictionary<NSString *, NSString *> *)headers returnCode:(NSInteger)returnCode responseTime:(NSTimeInterval)responseTime
{
    return [self initWithResponse:response headers:headers contentType:nil returnCode:returnCode responseTime:responseTime];
}

- (instancetype)initWithFileNamed:(NSString *)filename
{
    return [self initWithFileNamed:filename headers:nil returnCode:defaultReturnCode responseTime:defaultResponseTime];
}

- (instancetype)initWithFileNamed:(NSString *)filename responseTime:(NSTimeInterval)responseTime
{
    return [self initWithFileNamed:filename headers:nil returnCode:defaultReturnCode responseTime:responseTime];
}

- (instancetype)initWithFileNamed:(NSString *)filename returnCode:(NSInteger)returnCode
{
    return [self initWithFileNamed:filename headers:nil returnCode:returnCode responseTime:defaultResponseTime];
}

- (instancetype)initWithFileNamed:(NSString *)filename returnCode:(NSInteger)returnCode responseTime:(NSTimeInterval)responseTime
{
    return [self initWithFileNamed:filename headers:nil returnCode:returnCode responseTime:responseTime];
}

- (instancetype)initWithFileNamed:(NSString *)filename headers:( NSDictionary<NSString *, NSString *> *)headers returnCode:(NSInteger)returnCode responseTime:(NSTimeInterval)responseTime
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
    
    return [self initWithResponse:data headers:headers contentType:contentType returnCode:returnCode responseTime:responseTime];
}

#pragma clang diagnostic pop

#pragma mark - Accessors

- (NSData *)data
{
    return _data;
}

- (NSString *)contentType
{
    return _contentType;
}

- (NSDictionary *)headers
{
    return _headers;
}

- (NSInteger)returnCode
{
    return _returnCode;
}

- (NSTimeInterval)responseTime
{
    return _responseTime;
}

#pragma mark - Default overriders

+ (void)setDefaultResponseTime:(NSTimeInterval)responseTime
{
    defaultResponseTime = responseTime;
}

+ (void)setDefaultReturnCode:(NSInteger)returnCode
{
    defaultReturnCode = returnCode;
}

+ (void)setDictionaryDefaultContentType:(NSString *)contentType
{
    defaultNSDictionaryContentType = contentType;
}

+ (void)setDataDefaultContentType:(NSString *)contentType
{
    defaultNSDataContentType = contentType;
}

+ (void)setStringDefaultContentType:(NSString *)contentType
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
