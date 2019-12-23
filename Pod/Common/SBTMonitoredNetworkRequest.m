// SBTMonitoredNetworkRequest.m
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

#import "SBTMonitoredNetworkRequest.h"
#import "NSURLRequest+SBTUITestTunnelMatch.h"
#import "NSData+gzip.h"

@implementation SBTMonitoredNetworkRequest : NSObject

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.timestamp = [decoder decodeDoubleForKey:NSStringFromSelector(@selector(timestamp))];
        self.requestTime = [decoder decodeDoubleForKey:NSStringFromSelector(@selector(requestTime))];
        self.request = [decoder decodeObjectForKey:NSStringFromSelector(@selector(request))];
        self.originalRequest = [decoder decodeObjectForKey:NSStringFromSelector(@selector(originalRequest))];
        self.response = [decoder decodeObjectForKey:NSStringFromSelector(@selector(response))];
        self.responseData = [decoder decodeObjectForKey:NSStringFromSelector(@selector(responseData))];
        self.isStubbed = [decoder decodeBoolForKey:NSStringFromSelector(@selector(isStubbed))];
        self.isRewritten = [decoder decodeBoolForKey:NSStringFromSelector(@selector(isRewritten))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeDouble:self.timestamp forKey:NSStringFromSelector(@selector(timestamp))];
    [encoder encodeDouble:self.requestTime forKey:NSStringFromSelector(@selector(requestTime))];
    [encoder encodeObject:self.request forKey:NSStringFromSelector(@selector(request))];
    [encoder encodeObject:self.originalRequest forKey:NSStringFromSelector(@selector(originalRequest))];
    [encoder encodeObject:self.response forKey:NSStringFromSelector(@selector(response))];
    [encoder encodeObject:self.responseData forKey:NSStringFromSelector(@selector(responseData))];
    [encoder encodeBool:self.isStubbed forKey:NSStringFromSelector(@selector(isStubbed))];
    [encoder encodeBool:self.isRewritten forKey:NSStringFromSelector(@selector(isRewritten))];
}

- (NSString *)description
{
    NSString *ret = [NSString stringWithFormat:@"SBTUITestTunnel[%.4f] %@ %@", self.timestamp, self.originalRequest.HTTPMethod, self.originalRequest.URL.absoluteString];
    
    if (self.isStubbed) {
        return [ret stringByAppendingString:@" (Stubbed)"];
    } else if (self.isRewritten) {
        return [ret stringByAppendingString:@" (Rewritten)"];
    } else {
        return ret;
    }
}

- (NSString *)debugDescription
{
    NSMutableString *ret = [[self description] mutableCopy];
    if ([[self.originalRequest.allHTTPHeaderFields allKeys] count] > 0) {
        [ret appendString:[NSString stringWithFormat:@"|Headers: %@", self.originalRequest.allHTTPHeaderFields]];
    }
    
    NSString *uppercaseMethod = self.originalRequest.HTTPMethod;
    if ([uppercaseMethod isEqualToString:@"POST"]) {
        NSData *body = [self httpBodyFromRequest:self.originalRequest];
        if (body.length > 0) {
            [ret appendString:[NSString stringWithFormat:@"|HTTP Body: %@", [NSString stringWithUTF8String:[body bytes]]]];
        }
    }
    
    return ret;
}

- (NSString *)responseString
{
    NSString *ret = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    
    if (!ret) {
        ret = [[NSString alloc] initWithData:self.responseData encoding:NSASCIIStringEncoding];
    }
    
    return ret;
}

- (id)responseJSON
{
    if (!self.responseData) {
        return nil;
    }
    
    NSError *error = nil;
    id ret = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableContainers error:&error];
    
    return (ret && !error) ? ret : nil;
}

- (NSString *)requestString
{
    NSString *ret = [[NSString alloc] initWithData:[self httpBodyFromRequest:self.originalRequest] encoding:NSUTF8StringEncoding];
    
    if (!ret) {
        ret = [[NSString alloc] initWithData:[self httpBodyFromRequest:self.originalRequest] encoding:NSASCIIStringEncoding];
    }
    
    return ret;
}

- (id)requestJSON
{
    if (!self.originalRequest.HTTPBody) {
        return nil;
    }
    
    NSError *error = nil;
    id ret = [NSJSONSerialization JSONObjectWithData:[self httpBodyFromRequest:self.originalRequest] options:NSJSONReadingMutableContainers error:&error];
    
    return (ret && !error) ? ret : nil;
}

- (BOOL)matches:(SBTRequestMatch *)match
{
    return [self.originalRequest matches:match];
}

- (NSData *)httpBodyFromRequest:(NSURLRequest *)request
{
    if ([request.allHTTPHeaderFields[@"Content-Encoding"] isEqualToString:@"gzip"]) {
        return [request.HTTPBody gzipInflate];
    } else {
        return request.HTTPBody;
    }
}

@end

#endif
