// SBTRequestMatch.m
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

#import "include/SBTRequestMatch.h"
#import "private/SBTRegularExpressionMatcher.h"

@implementation NSDictionary (Matcher)

- (BOOL)matchExpectedHeaders:(NSDictionary<NSString *, NSString *> *)expectedHeaders
{
    for (NSString *key in expectedHeaders) {
        SBTRegularExpressionMatcher *keyMatcher = [[SBTRegularExpressionMatcher alloc] initWithRegularExpression:key];
        SBTRegularExpressionMatcher *valueMatcher = [[SBTRegularExpressionMatcher alloc] initWithRegularExpression:expectedHeaders[key]];

        BOOL matched = NO;
        for (NSString *headerKey in self) {
            if ([keyMatcher matches:headerKey] && [valueMatcher matches:self[headerKey]]) {
                matched = YES;
                break;
            }
        }
        if (!matched) {
            return NO;
        }
    }
    
    return YES;
}

@end

@implementation SBTRequestMatch : NSObject

- (instancetype)initWithURL:(NSString *)url query:(NSArray<NSString *> *)query method:(NSString *)method body:(NSString *)body requestHeaders:(NSDictionary<NSString *,NSString *> *)requestHeaders responseHeaders:(NSDictionary<NSString *,NSString *> *)responseHeaders
{
    if (self = [super init]) {
        self.url = url;
        self.query = query;
        self.method = method;
        self.body = body;
        self.requestHeaders = requestHeaders;
        self.responseHeaders = responseHeaders;
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
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

- (id)copyWithZone:(NSZone *)zone;
{
    SBTRequestMatch *copy = [SBTRequestMatch allocWithZone:zone];
    
    copy.url = [self.url copy];
    copy.query = [self.query copy];
    copy.method = [self.method copy];
    copy.body = [self.body copy];
    copy.requestHeaders = [self.requestHeaders copy];
    copy.responseHeaders = [self.responseHeaders copy];
    
    return copy;
}

- (NSString *)description
{
    NSString *ret = [NSString stringWithFormat:@"URL: %@\nQuery: %@\nMethod: %@\nBody: %@\nRequest headers: %@\nResponse headers: %@", self.url ?: @"N/A", self.query ?: @"N/A", self.method ?: @"N/A", self.body ?: @"N/A", self.requestHeaders ?: @"N/A", self.responseHeaders ?: @"N/A"];
    
    return ret;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if ([other isKindOfClass:[SBTRequestMatch class]]) {
        SBTRequestMatch *otherRequest = other;
        if ((self.url && ![self.url isEqualToString:otherRequest.url]) || (!self.url && otherRequest.url)) {
            return NO;
        }
        if ((self.query && ![self.query isEqual:otherRequest.query]) || (!self.query && otherRequest.query)) {
            return NO;
        }
        if ((self.method && ![self.method isEqualToString:otherRequest.method]) || (!self.method && otherRequest.method)) {
            return NO;
        }
        if ((self.body && ![self.body isEqualToString:otherRequest.body]) || (!self.body && otherRequest.body)) {
            return NO;
        }
        if ((self.requestHeaders && ![self.requestHeaders isEqual:otherRequest.requestHeaders]) || (!self.requestHeaders && otherRequest.requestHeaders)) {
            return NO;
        }
        if ((self.responseHeaders && ![self.responseHeaders isEqual:otherRequest.responseHeaders]) || (!self.responseHeaders && otherRequest.responseHeaders)) {
            return NO;
        }

        return YES;
    } else {
        return NO;
    }
}

- (NSUInteger)hash
{
    return self.url.hash ^ self.query.hash ^ self.method.hash ^ self.body.hash ^ self.requestHeaders.hash ^ self.responseHeaders.hash;
}

- (BOOL)matchesURLRequest:(nullable NSURLRequest *)request
{
    if (request == nil) {
        return NO;
    }
    
    if (self.method != nil && ![request.HTTPMethod isEqualToString:self.method]) {
        return NO;
    }

    // See https://github.com/Subito-it/SBTUITestTunnel/commit/11fa1b42e944b6b603da8a955deb906b71bcc1e8#diff-589a4a62fe1a450be8720c0eaa5a467dR373
    // if (![self matchesRequestHeaders:request.allHTTPHeaderFields]) {
    //    return NO;
    // }
    
    if (self.url != nil) {
        NSError *error;
        NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:self.url options:NSRegularExpressionCaseInsensitive error:&error];
        NSString *stringToMatch = request.URL.absoluteString;
        if (!error && stringToMatch != nil) {
            NSInteger matchCount = [regex numberOfMatchesInString:stringToMatch options:0 range:NSMakeRange(0, stringToMatch.length)];
            
            if (matchCount == 0) {
                return NO;
            }
        }
    }
    
    NSURL *requestUrl = request.URL;
    if (self.query != nil && requestUrl != nil) {
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:requestUrl resolvingAgainstBaseURL:NO];
        
        NSMutableString *queryString = [(components.query ?: @"") mutableCopy];
        [queryString insertString:@"&" atIndex:0]; // prepend & to allow always prepending `&` in SBTMatchRequest's queries
        
        for (NSString *matchQuery in self.query) {
            SBTRegularExpressionMatcher *matcher = [[SBTRegularExpressionMatcher alloc] initWithRegularExpression:matchQuery];
            
            if (![matcher matches:queryString]) {
                return NO;
            }
        }
    }
    
    if (self.body != nil) {
        SBTRegularExpressionMatcher *matcher = [[SBTRegularExpressionMatcher alloc] initWithRegularExpression:self.body];
        
        NSString *requestBody = [[NSString alloc] initWithData:request.HTTPBody ?: [NSData data] encoding:NSUTF8StringEncoding];
        
        if (![matcher matches:requestBody]) {
            return NO;
        }
    }

    return YES;
}

- (BOOL)matchesRequestHeaders:(nullable NSDictionary<NSString *, NSString *> *)requestHeaders
{
    if (requestHeaders == nil || [self.requestHeaders count] == 0) {
        return YES;
    }
    
    return [requestHeaders matchExpectedHeaders:self.requestHeaders];
}

- (BOOL)matchesResponseHeaders:(nullable NSDictionary<NSString *, NSString *> *)responseHeaders
{
    if (responseHeaders == nil || [self.responseHeaders count] == 0) {
        return YES;
    }
    
    return [responseHeaders matchExpectedHeaders:self.responseHeaders];
}

@end
