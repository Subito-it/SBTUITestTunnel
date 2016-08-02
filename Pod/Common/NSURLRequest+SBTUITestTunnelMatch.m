// NSURLRequest+SBTUITestTunnelMatch.m
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

#import "NSURLRequest+SBTUITestTunnelMatch.h"

@implementation NSURLRequest (SBTUITestTunnelMatch)

- (BOOL)matchesRegexPattern:(NSString *)regexPattern
{
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:regexPattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSString *requestAbsoluteString = self.URL.absoluteString;
    NSUInteger regexMatches = [regex numberOfMatchesInString:requestAbsoluteString options:0 range:NSMakeRange(0, [requestAbsoluteString length])];
    
    return regexMatches > 0;
}

- (BOOL)matchesQueryParams:(NSArray<NSString *> *)queries
{
    NSDictionary<NSString *, NSString *> *requestParams = nil;
    
    if ([self.HTTPMethod isEqualToString:@"POST"]) {
        requestParams = [NSURLProtocol propertyForKey:@"parameters" inRequest:self];
    } else if ([self.HTTPMethod isEqualToString:@"GET"]) {
        NSURLComponents *components = [NSURLComponents componentsWithURL:self.URL resolvingAgainstBaseURL:NO];
        
        NSMutableDictionary<NSString *, NSString *> *mRequestParams = [NSMutableDictionary dictionary];
        for (NSURLQueryItem *queryItem in components.queryItems) {
            mRequestParams[queryItem.name] = queryItem.value;
        }
        
        requestParams = mRequestParams;
    }
    
    for (NSString *query in queries) {
        __block BOOL found = NO;
        
        NSArray *queryComponents = [query componentsSeparatedByString:@"="];
        NSString *queryKey = [queryComponents firstObject];
        NSString *queryValue = nil;
        if (queryComponents.count == 2) {
            queryValue = [queryComponents lastObject];
        }
        
        [requestParams enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            if ([key isEqualToString:queryKey] && (!queryValue || [value isEqualToString:queryValue])) {
                found = YES;
                *stop = YES;
            }
        }];
        
        if (!found) {
            return NO;
        }
    }
    
    return YES;
}

@end

#endif
