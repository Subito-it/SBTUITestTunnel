// SBTStubResponse.m
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

#import "include/SBTStubResponse.h"

NSString * const SBTResponseContentTypeJson = @"application/json";
NSString * const SBTResponseContentTypeXml = @"application/xml";
NSString * const SBTResponseContentTypeText = @"text/plain";
NSString * const SBTResponseContentTypeData = @"application/octet-stream";
NSString * const SBTResponseContentTypeHtml = @"text/html";
NSString * const SBTResponseContentTypePdf = @"application/pdf";
NSString * const SBTResponseContentPKPass = @"application/vnd.apple.pkpass";

@interface SBTResponseDefaults: NSObject
    @property (nonatomic, assign) NSTimeInterval responseTime;
    @property (nonatomic, assign) NSInteger returnCode;
    @property (nonnull, nonatomic, strong) NSString *contentTypeDictionary;
    @property (nonnull, nonatomic, strong) NSString *contentTypeString;
    @property (nonnull, nonatomic, strong) NSString *contentTypeData;
@end

@implementation SBTResponseDefaults

- (nonnull instancetype)init
{
    if (self = [super init]) {
        self.responseTime = 0.0;
        self.returnCode = 200;
        self.contentTypeDictionary = SBTResponseContentTypeJson;
        self.contentTypeString = SBTResponseContentTypeText;
        self.contentTypeData = SBTResponseContentTypeData;
    }
    
    return self;
}

@end

@interface SBTStubResponse()

@property (class, nonnull, nonatomic, strong) SBTResponseDefaults *defaults;

@end

@implementation SBTStubResponse : NSObject

static SBTResponseDefaults *_defaults;

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithResponse:(NSObject *)response
                         headers:(NSDictionary<NSString *, NSString *> *)headers
                     contentType:(NSString *)contentType
                      returnCode:(NSInteger)returnCode
                    responseTime:(NSTimeInterval)responseTime
                activeIterations:(NSInteger)activeIterations
{    
    if (self = [super init]) {
        if ([response isKindOfClass:[NSData class]]) {
            self.data = (NSData *)response;
        } else if ([response isKindOfClass:[NSString class]]) {
            self.data = [(NSString *)response dataUsingEncoding:NSUTF8StringEncoding];
        } else if ([response isKindOfClass:[NSDictionary class]]) {
            NSError *error = nil;
            NSData *data = [NSJSONSerialization dataWithJSONObject:(NSDictionary *)response options:0 error:&error];
            if (error != nil) {
                NSAssert(NO, @"Failed serializing response");
            }
            
            self.data = data;
        } else {
            NSAssert(NO, @"Invalid response type, expecting NSData, NSString or NSDictionary");
        }
        
        NSString *stubContentType;
        if (contentType != nil) {
            stubContentType = contentType;
        } else if (headers[@"Content-Type"] != nil) {
            stubContentType = headers[@"Content-Type"];
        } else {
            if ([response isKindOfClass:[NSData class]]) {
                stubContentType = [self class].defaults.contentTypeData;
            } else if ([response isKindOfClass:[NSString class]]) {
                stubContentType = [self class].defaults.contentTypeString;
            } else if ([response isKindOfClass:[NSDictionary class]]) {
                stubContentType = [self class].defaults.contentTypeDictionary;
            } else {
                NSAssert(NO, @"Invalid response type, expecting NSData, NSString or NSDictionary");
            }
        }
        self.contentType = stubContentType;
        
        NSMutableDictionary *mHeaders = [(headers ?: @{}) mutableCopy];
        mHeaders[@"Content-Type"] = self.contentType;
        self.headers = mHeaders;
        
        self.returnCode = returnCode != -1 ? returnCode : [self class].defaults.returnCode;
        self.responseTime = responseTime != NSTimeIntervalSince1970 ? responseTime : [self class].defaults.responseTime;
        self.activeIterations = activeIterations;
    }
    
    return self;
}


- (instancetype)initWithFileNamed:(NSString *)fileNamed
                          headers:(NSDictionary<NSString *, NSString *> *)headers
                       returnCode:(NSInteger)returnCode
                     responseTime:(NSTimeInterval)responseTime
                 activeIterations:(NSInteger)activeIterations
{
    NSURL *url = [[NSURL alloc] initWithString:fileNamed];
    NSAssert(url != nil, @"Invalid filename provided");
    
    NSString *stubName = [url URLByDeletingPathExtension].lastPathComponent;
    NSString *stubExtension = url.pathExtension;
    
    NSData *stubData;
    NSURL *dataUrl = [[NSBundle bundleForClass:[self class]] URLForResource:stubName withExtension:stubExtension];
    if (dataUrl != nil) {
        stubData = [NSData dataWithContentsOfURL:dataUrl];
    }
    
    if (stubData == nil) {
        for (NSBundle *bundle in NSBundle.allBundles) {
            BOOL isTestBundle = [bundle.bundlePath hasSuffix:@".xctest"];
            NSURL *dataUrl = [bundle URLForResource:stubName withExtension:stubExtension];
            if (dataUrl != nil && isTestBundle) {
                stubData = [NSData dataWithContentsOfURL:dataUrl];
                break;
            }
        }
    }
    
    NSAssert(stubData != nil, @"No data found in stub");
    
    NSString *contentType;
    NSString *loweredStubExtension = stubExtension.lowercaseString;
    if ([loweredStubExtension isEqualToString:@"json"]) {
        contentType = SBTResponseContentTypeJson;
    } else if ([loweredStubExtension isEqualToString:@"xml"]) {
        contentType = SBTResponseContentTypeXml;
    } else if ([loweredStubExtension isEqualToString:@"txt"]) {
        contentType = SBTResponseContentTypeText;
    } else if ([loweredStubExtension isEqualToString:@"html"]) {
        contentType = SBTResponseContentTypeHtml;
    } else if ([loweredStubExtension isEqualToString:@"pdf"]) {
        contentType = SBTResponseContentTypePdf;
    } else if ([loweredStubExtension isEqualToString:@"pkpass"]){
        contentType = SBTResponseContentPKPass;
    } else {
        NSAssert(NO, @"Unsupported file extension. Expecting json, xml, txt, htm, html, pdf, pkpass");
    }
    
    return [self initWithResponse:stubData headers:headers contentType:contentType returnCode:returnCode responseTime:responseTime activeIterations:activeIterations];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.data = [decoder decodeObjectOfClass:[NSData class] forKey:NSStringFromSelector(@selector(data))];
        self.contentType = [decoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(contentType))];

        NSSet *dictClasses = [NSSet setWithObjects:[NSDictionary class], [NSString class], nil];
        self.headers = [decoder decodeObjectOfClasses:dictClasses forKey:NSStringFromSelector(@selector(headers))];

        self.returnCode = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(returnCode))];
        self.responseTime = [decoder decodeDoubleForKey:NSStringFromSelector(@selector(responseTime))];
        self.activeIterations = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(activeIterations))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.data forKey:NSStringFromSelector(@selector(data))];
    [encoder encodeObject:self.contentType forKey:NSStringFromSelector(@selector(contentType))];
    [encoder encodeObject:self.headers forKey:NSStringFromSelector(@selector(headers))];
    [encoder encodeInteger:self.returnCode forKey:NSStringFromSelector(@selector(returnCode))];
    [encoder encodeDouble:self.responseTime forKey:NSStringFromSelector(@selector(responseTime))];
    [encoder encodeInteger:self.activeIterations forKey:NSStringFromSelector(@selector(activeIterations))];
}

- (id)copyWithZone:(NSZone *)zone;
{
    SBTStubResponse *copy = [SBTStubResponse allocWithZone:zone];
    
    copy.data = [self.data copy];
    copy.contentType = [self.contentType copy];
    copy.headers = [self.headers copy];
    copy.returnCode = self.returnCode;
    copy.responseTime = self.responseTime;
    copy.activeIterations = self.activeIterations;
    
    return copy;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if ([other isKindOfClass:[SBTStubResponse class]]) {
        SBTStubResponse *otherRequest = other;
        if (self.data && ![self.data isEqual:otherRequest.data]) {
            return NO;
        }
        if (self.contentType && ![self.contentType isEqualToString:otherRequest.contentType]) {
            return NO;
        }
        if (self.headers && ![self.headers isEqual:otherRequest.headers]) {
            return NO;
        }

        return self.returnCode == otherRequest.returnCode &&
               self.responseTime == otherRequest.responseTime &&
               self.activeIterations == otherRequest.activeIterations;
    } else {
        return NO;
    }
}

- (NSUInteger)hash
{
    return self.data.hash ^ self.contentType.hash ^ self.headers.hash ^ self.returnCode ^ (unsigned long)self.responseTime ^ self.activeIterations;
}

// MARK: - Default overriders

/// Reset defaults values of responseTime, returnCode and contentTypes
+ (void)resetUnspecifiedDefaults
{
    self.defaults = [[SBTResponseDefaults alloc] init];
}

+ (SBTResponseDefaults *)defaults
{
    if (_defaults == nil) {
        _defaults = [[SBTResponseDefaults alloc] init];
    }
    return _defaults;
}

+ (void)setDefaults:(SBTResponseDefaults *)defaults
{
    _defaults = defaults;
}

+ (NSTimeInterval)defaultResponseTime
{
    return [self defaults].responseTime;
}

+ (void)setDefaultResponseTime:(NSTimeInterval)timeInterval
{
    [self defaults].responseTime = timeInterval;
}

+ (NSInteger)defaultReturnCode
{
    return [self defaults].returnCode;
}

+ (void)setDefaultReturnCode:(NSInteger)returnCode
{
    [self defaults].returnCode = returnCode;
}

+ (NSString *)defaultDictionaryContentType
{
    return [self defaults].contentTypeDictionary;
}

+ (void)setDefaultDictionaryContentType:(NSString *)defaultDictionaryContentType
{
    [self defaults].contentTypeDictionary = defaultDictionaryContentType;
}

+ (NSString *)defaultDataContentType
{
    return [self defaults].contentTypeData;
}

+ (void)setDefaultDataContentType:(NSString *)defaultDataContentType
{
    [self defaults].contentTypeData = defaultDataContentType;
}

+ (NSString *)defaultStringContentType
{
    return [self defaults].contentTypeString;
}

+ (void)setDefaultStringContentType:(NSString *)defaultStringContentType
{
    [self defaults].contentTypeString = defaultStringContentType;
}

@end
