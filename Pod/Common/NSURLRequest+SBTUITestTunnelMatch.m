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
    #ifndef ENABLE_UITUNNEL 
        #define ENABLE_UITUNNEL 1
    #endif
#endif

#if ENABLE_UITUNNEL

#import "NSURLRequest+SBTUITestTunnelMatch.h"
#import "SBTUITestTunnel.h"

@implementation NSURLRequest (SBTUITestTunnelMatch)

- (BOOL)matches:(SBTRequestMatch *)match
{
    BOOL matchesURL = YES;
    if (match.url) {
        NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:match.url options:NSRegularExpressionCaseInsensitive error:nil];
        NSString *stringToMatch = self.URL.absoluteString;
        NSUInteger regexMatches = [regex numberOfMatchesInString:stringToMatch options:0 range:NSMakeRange(0, stringToMatch.length)];
        
        matchesURL = regexMatches > 0;
    }

    BOOL matchesQuery = YES;
    if (match.query) {
        NSString *queryString = nil;
        
        if ([self.HTTPMethod isEqualToString:@"POST"] || [self.HTTPMethod isEqualToString:@"PUT"]) {
            NSData *requestData = [NSURLProtocol propertyForKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:self];
            queryString = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
        } else if ([self.HTTPMethod isEqualToString:@"GET"] || [self.HTTPMethod isEqualToString:@"DELETE"]) {
            NSURLComponents *components = [NSURLComponents componentsWithURL:self.URL resolvingAgainstBaseURL:NO];
            
            queryString = components.query ?: @"";
        }
        
        if (queryString) {
            NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:match.query options:NSRegularExpressionCaseInsensitive error:nil];
            NSUInteger regexMatches = [regex numberOfMatchesInString:queryString options:0 range:NSMakeRange(0, queryString.length)];
            matchesQuery = regexMatches > 0;
        }
    }

    BOOL matchesMethod = YES;
    if (match.method) {
        matchesMethod = [self.HTTPMethod isEqualToString:match.method];
    }

    return matchesURL && matchesQuery && matchesMethod;
}

@end

#endif
