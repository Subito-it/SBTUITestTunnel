// SBTRewrite.m
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

#import "include/SBTRewrite.h"
#import "include/SBTRewriteReplacement.h"

@implementation SBTRewrite : NSObject

- (instancetype)initWithUrlReplacement:(NSArray<SBTRewriteReplacement *> *)urlReplacement
                    requestReplacement:(NSArray<SBTRewriteReplacement *> *)requestReplacement
                   responseReplacement:(NSArray<SBTRewriteReplacement *> *)responseReplacement
             requestHeadersReplacement:(NSDictionary<NSString *, NSString *> *)requestHeadersReplacement
            responseHeadersReplacement:(NSDictionary<NSString *, NSString *> *)responseHeadersReplacement
                    responseStatusCode:(NSInteger)responseStatusCode
                      activeIterations:(NSInteger)activeIterations
{
    if (self = [super init]) {
        self.urlReplacement = urlReplacement;
        self.requestReplacement = requestReplacement;
        self.responseReplacement = responseReplacement;
        self.requestHeadersReplacement = requestHeadersReplacement;
        self.responseHeadersReplacement = responseHeadersReplacement;
        self.responseStatusCode = responseStatusCode;
        self.activeIterations = activeIterations;
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.urlReplacement = [decoder decodeObjectForKey:NSStringFromSelector(@selector(urlReplacement))];
        self.requestReplacement = [decoder decodeObjectForKey:NSStringFromSelector(@selector(requestReplacement))];
        self.responseReplacement = [decoder decodeObjectForKey:NSStringFromSelector(@selector(responseReplacement))];
        self.requestHeadersReplacement = [decoder decodeObjectForKey:NSStringFromSelector(@selector(requestHeadersReplacement))];
        self.responseHeadersReplacement = [decoder decodeObjectForKey:NSStringFromSelector(@selector(responseHeadersReplacement))];
        self.responseStatusCode = [decoder decodeIntForKey:NSStringFromSelector(@selector(responseStatusCode))];
        self.activeIterations = [decoder decodeIntForKey:NSStringFromSelector(@selector(activeIterations))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.urlReplacement forKey:NSStringFromSelector(@selector(urlReplacement))];
    [encoder encodeObject:self.requestReplacement forKey:NSStringFromSelector(@selector(requestReplacement))];
    [encoder encodeObject:self.responseReplacement forKey:NSStringFromSelector(@selector(responseReplacement))];
    [encoder encodeObject:self.requestHeadersReplacement forKey:NSStringFromSelector(@selector(requestHeadersReplacement))];
    [encoder encodeObject:self.responseHeadersReplacement forKey:NSStringFromSelector(@selector(responseHeadersReplacement))];
    [encoder encodeInt:(int)self.responseStatusCode forKey:NSStringFromSelector(@selector(responseStatusCode))];
    [encoder encodeInt:(int)self.activeIterations forKey:NSStringFromSelector(@selector(activeIterations))];
}

- (NSString *)description
{
    NSMutableArray<NSString *> *descriptionArray = [NSMutableArray array];
    
    for (SBTRewriteReplacement *replacement in self.urlReplacement) {
        [descriptionArray addObject:[NSString stringWithFormat:@"URL replacement: %@", [replacement description]]];
    }
    for (SBTRewriteReplacement *replacement in self.responseReplacement) {
        [descriptionArray addObject:[NSString stringWithFormat:@"Response body replacement: %@", [replacement description]]];
    }
    for (NSString *key in self.responseHeadersReplacement) {
        [descriptionArray addObject:[NSString stringWithFormat:@"Response header replacement: `%@` -> `%@`", key, self.responseHeadersReplacement[key]]];
    }
    if (self.responseStatusCode > -1) {
        [descriptionArray addObject:[NSString stringWithFormat:@"Response code replacement: %ld", self.responseStatusCode]];
    }
    for (SBTRewriteReplacement *replacement in self.requestReplacement) {
        [descriptionArray addObject:[NSString stringWithFormat:@"Request body replacement: %@", [replacement description]]];
    }
    for (NSString *key in self.requestHeadersReplacement) {
        [descriptionArray addObject:[NSString stringWithFormat:@"Request header replacement: `%@` -> `%@`", key, self.requestHeadersReplacement[key]]];
    }
    if (self.activeIterations > 0) {
        [descriptionArray addObject:[NSString stringWithFormat:@"Iterations left: %ld", self.activeIterations]];
    }
    
    return [descriptionArray componentsJoinedByString:@"\n"];
}

- (NSURL *)rewriteUrl:(NSURL *)url
{
    if (self.urlReplacement.count == 0) {
        return url;
    }
    
    NSString *absoluteString = url.absoluteString;
    for (SBTRewriteReplacement *replacement in self.urlReplacement) {
        absoluteString = [replacement replace:absoluteString];
    }
    
    return [NSURL URLWithString:absoluteString] ?: url;
}

- (NSDictionary<NSString *, NSString *> *)rewriteRequestHeaders:(NSDictionary<NSString *, NSString *> *)requestHeaders
{
    if (self.requestHeadersReplacement.count == 0) {
        return requestHeaders;
    }
    
    NSMutableDictionary<NSString *, NSString *> *headers = [requestHeaders mutableCopy];
    for (NSString *key in self.requestHeadersReplacement) {
        NSString *value = self.requestHeadersReplacement[key];
        if (value.length == 0) {
            [headers removeObjectForKey:key];
        } else {
            headers[key] = value;
        }
    }

    return headers;
}

- (NSDictionary<NSString *, NSString *> *)rewriteResponseHeaders:(NSDictionary<NSString *, NSString *> *)responseHeaders
{
    if (self.responseHeadersReplacement.count == 0) {
        return responseHeaders;
    }
    
    NSMutableDictionary<NSString *, NSString *> *headers = [responseHeaders mutableCopy];
    for (NSString *key in self.responseHeadersReplacement) {
        NSString *value = self.responseHeadersReplacement[key];
        if (value.length == 0) {
            [headers removeObjectForKey:key];
        } else {
            headers[key] = value;
        }
    }

    return headers;
}

- (NSData *)rewriteRequestBody:(NSData *)requestBody
{
    if (self.requestReplacement.count == 0) {
        return requestBody;
    }
    
    NSString *body = [[NSString alloc] initWithData:requestBody encoding:NSUTF8StringEncoding];
    for (SBTRewriteReplacement *replacement in self.requestReplacement) {
        body = [replacement replace:body];
    }
    
    return [body dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)rewriteResponseBody:(NSData *)responseBody
{
    if (self.responseReplacement.count == 0) {
        return responseBody;
    }
    
    NSString *body = [[NSString alloc] initWithData:responseBody encoding:NSUTF8StringEncoding];
    for (SBTRewriteReplacement *replacement in self.responseReplacement) {
        body = [replacement replace:body];
    }
    
    return [body dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSInteger)rewriteStatusCode:(NSInteger)statusCode
{
    return self.responseStatusCode < 0 ? statusCode : self.responseStatusCode;
}

@end
