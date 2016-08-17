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
#import "SBTUITestTunnel.h"

@implementation NSURLRequest (SBTUITestTunnelMatch)

- (BOOL)matchesRegexPattern:(NSString *)regexPattern
{
    NSString *requestString = nil;
    
    if ([self.HTTPMethod isEqualToString:@"POST"] || [self.HTTPMethod isEqualToString:@"PUT"]) {
        NSData *requestData = [NSURLProtocol propertyForKey:SBTUITunneledNSURLProtocolHTTPBodyKey inRequest:self];
        requestString = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
    } else if ([self.HTTPMethod isEqualToString:@"GET"] || [self.HTTPMethod isEqualToString:@"DELETE"]) {
        NSURLComponents *components = [NSURLComponents componentsWithURL:self.URL resolvingAgainstBaseURL:NO];
        
        requestString = components.query;
    }
    
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:regexPattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSString *requestURLString = self.URL.absoluteString;
    NSUInteger regexMatchesURL = [regex numberOfMatchesInString:requestURLString options:0 range:NSMakeRange(0, requestURLString.length)];
    
    NSUInteger regexMatchesRequest = [regex numberOfMatchesInString:requestString options:0 range:NSMakeRange(0, requestString.length)];
    
    return regexMatchesURL > 0 || regexMatchesRequest > 0;
}

@end

#endif
