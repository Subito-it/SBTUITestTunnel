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

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    NSData *findData = [decoder decodeObjectForKey:NSStringFromSelector(@selector(findData))];
    NSData *replaceData = [decoder decodeObjectForKey:NSStringFromSelector(@selector(replaceData))];
    
    NSString *find = [[NSString alloc] initWithData:findData encoding:NSUTF8StringEncoding];
    NSString *replace = [[NSString alloc] initWithData:replaceData encoding:NSUTF8StringEncoding];

    SBTRewriteReplacement *ret = [self initWithFind:find replace:replace];
    
    return ret;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.findData forKey:NSStringFromSelector(@selector(findData))];
    [encoder encodeObject:self.replaceData forKey:NSStringFromSelector(@selector(replaceData))];
}

- (instancetype)initWithFind:(NSString *)find replace:(NSString *)replace
{
    if ((self = [super init])) {
        self.findData = [find dataUsingEncoding:NSUTF8StringEncoding];
        self.replaceData = [replace dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    return self;
}

- (NSString *)description
{
    NSString *findString = [[NSString alloc] initWithData:self.findData encoding:NSUTF8StringEncoding];
    NSString *replaceString = [[NSString alloc] initWithData:self.replaceData encoding:NSUTF8StringEncoding];

    return [[NSString alloc] initWithFormat:@"`%@` -> `%@`", findString, replaceString];
}

- (NSString *)replace:(NSString *)string
{
    NSString *findString = [[NSString alloc] initWithData:self.findData encoding:NSUTF8StringEncoding];
    NSString *replaceString = [[NSString alloc] initWithData:self.replaceData encoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:findString options:NSRegularExpressionCaseInsensitive error:&error];
    
    if (error != nil) {
        return @"invalid-regex!";
    }
    
    return [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:replaceString];
}

@end

#pragma mark - SBTRewrite

@interface SBTRewrite()

@property (nonatomic, strong) NSArray<SBTRewriteReplacement *> *urlReplacement;
@property (nonatomic, strong) NSArray<SBTRewriteReplacement *> *requestReplacement;
@property (nonatomic, strong) NSArray<SBTRewriteReplacement *> *responseReplacement;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *requestHeadersReplacement;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *responseHeadersReplacement;
@property (nonatomic, assign) NSInteger responseCode;

@end

@implementation SBTRewrite

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    NSArray<SBTRewriteReplacement *> *urlReplacement = [decoder decodeObjectForKey:NSStringFromSelector(@selector(urlReplacement))];
    NSArray<SBTRewriteReplacement *> *requestReplacement = [decoder decodeObjectForKey:NSStringFromSelector(@selector(requestReplacement))];
    NSArray<SBTRewriteReplacement *> *responseReplacement = [decoder decodeObjectForKey:NSStringFromSelector(@selector(responseReplacement))];
    NSDictionary<NSString *, NSString *> *requestHeadersReplacement = [decoder decodeObjectForKey:NSStringFromSelector(@selector(requestHeadersReplacement))];
    NSDictionary<NSString *, NSString *> *responseHeadersReplacement = [decoder decodeObjectForKey:NSStringFromSelector(@selector(responseHeadersReplacement))];
    NSInteger responseCode = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(responseCode))];

    return [self initWithUrlReplacement:urlReplacement
                     requestReplacement:requestReplacement
              requestHeadersReplacement:requestHeadersReplacement
                    responseReplacement:responseReplacement
             responseHeadersReplacement:responseHeadersReplacement
                           responseCode:responseCode];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.urlReplacement forKey:NSStringFromSelector(@selector(urlReplacement))];
    [encoder encodeObject:self.requestReplacement forKey:NSStringFromSelector(@selector(requestReplacement))];
    [encoder encodeObject:self.responseReplacement forKey:NSStringFromSelector(@selector(responseReplacement))];
    [encoder encodeObject:self.requestHeadersReplacement forKey:NSStringFromSelector(@selector(requestHeadersReplacement))];
    [encoder encodeObject:self.responseHeadersReplacement forKey:NSStringFromSelector(@selector(responseHeadersReplacement))];
    [encoder encodeInteger:self.responseCode forKey:NSStringFromSelector(@selector(responseCode))];
}

#pragma mark - Response

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (instancetype)initWithResponseReplacement:(NSArray<SBTRewriteReplacement *> *)responseReplacement
                                 headersReplacement:(NSDictionary<NSString *, NSString *> *)responseHeadersReplacement
                                       responseCode:(NSInteger)responseCode
{
    return [self initWithUrlReplacement:nil
                     requestReplacement:nil
              requestHeadersReplacement:nil
                    responseReplacement:responseReplacement
             responseHeadersReplacement:responseHeadersReplacement
                           responseCode:responseCode];
}

- (instancetype)initWithResponseReplacement:(NSArray<SBTRewriteReplacement *> *)responseReplacement
                                 headersReplacement:(NSDictionary<NSString *, NSString *> *)responseHeadersReplacement
{
    return [self initWithUrlReplacement:nil
                     requestReplacement:nil
              requestHeadersReplacement:nil
                    responseReplacement:responseReplacement
             responseHeadersReplacement:responseHeadersReplacement
                           responseCode:-1];
}

- (instancetype)initWithResponseReplacement:(NSArray<SBTRewriteReplacement *> *)responseReplacement
{
    return [self initWithUrlReplacement:nil
                     requestReplacement:nil
              requestHeadersReplacement:nil
                    responseReplacement:responseReplacement
             responseHeadersReplacement:nil
                           responseCode:-1];
}

- (instancetype)initWithResponseHeadersReplacement:(NSDictionary<NSString *, NSString *> *)responseHeadersReplacement
{
    return [self initWithUrlReplacement:nil
                     requestReplacement:nil
              requestHeadersReplacement:nil
                    responseReplacement:nil
             responseHeadersReplacement:responseHeadersReplacement
                           responseCode:-1];
}

- (instancetype)initWithResponseStatusCode:(NSInteger)statusCode
{
    return [self initWithUrlReplacement:nil
                     requestReplacement:nil
              requestHeadersReplacement:nil
                    responseReplacement:nil
             responseHeadersReplacement:nil
                           responseCode:statusCode];
}

#pragma mark - Request

- (instancetype)initWithRequestReplacement:(NSArray<SBTRewriteReplacement *> *)requestReplacement
                         requestHeadersReplacement:(NSDictionary<NSString *, NSString *> *)requestHeadersReplacement
{
    return [self initWithUrlReplacement:nil
                     requestReplacement:requestReplacement
              requestHeadersReplacement:requestHeadersReplacement
                    responseReplacement:nil
             responseHeadersReplacement:nil
                           responseCode:-1];
}

- (instancetype)initWithRequestReplacement:(NSArray<SBTRewriteReplacement *> *)requestReplacement
{
    return [self initWithUrlReplacement:nil
                     requestReplacement:requestReplacement
              requestHeadersReplacement:nil
                    responseReplacement:nil
             responseHeadersReplacement:nil
                           responseCode:-1];
}

- (instancetype)initWithRequestHeadersReplacement:(NSDictionary<NSString *, NSString *> *)requestHeadersReplacement
{
    return [self initWithUrlReplacement:nil
                     requestReplacement:nil
              requestHeadersReplacement:requestHeadersReplacement
                    responseReplacement:nil
             responseHeadersReplacement:nil
                           responseCode:-1];
}

#pragma mark - URL

- (instancetype)initWithRequestUrlReplacement:(NSArray<SBTRewriteReplacement *> *)urlReplacement
{
    return [self initWithUrlReplacement:urlReplacement
                     requestReplacement:nil
              requestHeadersReplacement:nil
                    responseReplacement:nil
             responseHeadersReplacement:nil
                           responseCode:-1];
}

#pragma mark - Designated

- (instancetype)initWithUrlReplacement:(NSArray<SBTRewriteReplacement *> *)urlReplacement
                    requestReplacement:(NSArray<SBTRewriteReplacement *> *)requestReplacement
             requestHeadersReplacement:(NSDictionary<NSString *, NSString *> *)requestHeadersReplacement
                   responseReplacement:(NSArray<SBTRewriteReplacement *> *)responseReplacement
            responseHeadersReplacement:(NSDictionary<NSString *, NSString *> *)responseHeadersReplacement
                          responseCode:(NSInteger)responseCode
{
    if ((self = [super init])) {
        self.urlReplacement = urlReplacement ?: @[];
        
        self.responseReplacement = responseReplacement ?: @[];
        self.requestReplacement = requestReplacement ?: @[];
        
        self.responseHeadersReplacement = responseHeadersReplacement ?: @{};
        self.requestHeadersReplacement = requestHeadersReplacement ?: @{};
        
        self.responseCode = responseCode;
    }
    
    return self;
}

#pragma clang diagnostic pop

- (NSString *)description
{
    NSMutableString *description = [NSMutableString string];
    
    if (self.urlReplacement.count > 0) {
        for (SBTRewriteReplacement *replacement in self.urlReplacement) {
            [description appendFormat:@"URL replacement: %@\n", replacement];
        }
        [description appendString:@"\n"];
    }
    
    if (self.responseReplacement.count > 0) {
        for (SBTRewriteReplacement *replacement in self.responseReplacement) {
            [description appendFormat:@"Response body replacement: %@\n", replacement];
        }
        [description appendString:@"\n"];
    }
    
    if (self.responseHeadersReplacement.count > 0) {
        for (NSString *replacementKey in self.responseHeadersReplacement) {
            [description appendFormat:@"Response header replacement: `%@` -> `%@`\n", replacementKey, self.responseHeadersReplacement[replacementKey]];
        }
        [description appendString:@"\n"];
    }
    
    if (self.responseCode > -1) {
        [description appendFormat:@"Response code replacement: %ld\n\n", (long)self.responseCode];
    }
    
    if (self.requestReplacement.count > 0) {
        for (SBTRewriteReplacement *replacement in self.requestReplacement) {
            [description appendFormat:@"Request body replacement: %@\n", replacement];
        }
        [description appendString:@"\n"];
    }
    
    if (self.requestHeadersReplacement.count > 0) {
        for (NSString *replacementKey in self.requestHeadersReplacement) {
            [description appendFormat:@"Request header replacement: `%@` -> `%@`\n", replacementKey, self.requestHeadersReplacement[replacementKey]];
        }
        [description appendString:@"\n"];
    }

    return description;
}

- (NSURL *)rewriteUrl:(nonnull NSURL *)url
{
    if (self.urlReplacement.count == 0) {
        return url;
    }
    
    NSMutableString *absoluteString = [url.absoluteString mutableCopy];
    for (SBTRewriteReplacement *replacement in self.urlReplacement) {
        absoluteString = [[replacement replace:absoluteString] mutableCopy];
    }
    
    return [NSURL URLWithString:absoluteString];
}

- (NSDictionary *)rewriteRequestHeaders:(NSDictionary *)requestHeaders
{
    if (self.requestHeadersReplacement.allKeys.count == 0) {
        return requestHeaders;
    }
    
    NSMutableDictionary *headers = [requestHeaders mutableCopy];
    for (NSString *replacementKey in self.requestHeadersReplacement) {
        BOOL shouldRemoveKey = self.requestHeadersReplacement[replacementKey].length == 0;
        
        if (shouldRemoveKey) {
            [headers removeObjectForKey:replacementKey];
        } else {
            headers[replacementKey] = self.requestHeadersReplacement[replacementKey];
        }
    }
    
    return headers;
}

- (NSDictionary *)rewriteResponseHeaders:(NSDictionary *)responseHeaders
{
    if (self.responseHeadersReplacement.allKeys.count == 0) {
        return responseHeaders;
    }
    
    NSMutableDictionary *headers = [responseHeaders mutableCopy];
    for (NSString *replacementKey in self.responseHeadersReplacement) {
        BOOL shouldRemoveKey = (self.responseHeadersReplacement[replacementKey].length == 0);
        
        if (shouldRemoveKey) {
            [headers removeObjectForKey:replacementKey];
        } else {
            headers[replacementKey] = self.responseHeadersReplacement[replacementKey];
        }
    }
    
    return headers;
}

- (NSData *)rewriteRequestBody:(NSData *)requestBody
{
    if (self.requestReplacement.count == 0) {
        return requestBody;
    }
    
    // For the time being we rewrite Strings, it would be nice to be able to rewrite NSData bodies (find a sequence of bytes and replace them)
    NSMutableString *body = [[NSMutableString alloc] initWithData:requestBody encoding:NSUTF8StringEncoding];
    if (!body) {
        return requestBody;
    }
    
    for (SBTRewriteReplacement *replacement in self.requestReplacement) {
        body = [[replacement replace:body] mutableCopy];
    }
    
    NSData *rewrittenData = [body dataUsingEncoding:NSUTF8StringEncoding];
    return rewrittenData ?: requestBody;
}

- (NSData *)rewriteResponseBody:(NSData *)responseBody
{
    if (self.responseReplacement.count == 0) {
        return responseBody;
    }
    
    // For the time being we rewrite Strings, it would be nice to be able to rewrite NSData bodies (find a sequence of bytes and replace them)
    NSMutableString *body = [[NSMutableString alloc] initWithData:responseBody encoding:NSUTF8StringEncoding];
    if (!body) {
        return responseBody;
    }
    
    for (SBTRewriteReplacement *replacement in self.responseReplacement) {
        body = [[replacement replace:body] mutableCopy];
    }
    
    NSData *rewrittenData = [body dataUsingEncoding:NSUTF8StringEncoding];
    return rewrittenData ?: responseBody;
}

- (NSInteger)rewriteStatusCode:(NSInteger)statusCode
{
    if (self.responseCode < 0) {
        return statusCode;
    }
    
    return self.responseCode;
}

@end

#endif
