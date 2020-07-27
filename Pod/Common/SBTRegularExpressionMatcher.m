// SBTRegularExpressionMatcher.m
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

#import "SBTRegularExpressionMatcher.h"

@interface SBTRegularExpressionMatcher()

@property (nonatomic, assign) BOOL invertMatch;
@property (nonatomic, strong) NSRegularExpression *regex;

@end

@implementation SBTRegularExpressionMatcher

- (instancetype)initWithRegularExpression:(NSString *)regexString
{
    if (self = [super init]) {
        BOOL invertMatch = [regexString hasPrefix:@"!"];
        // skip first char for inverted matches
        NSString *pattern = [regexString substringFromIndex:invertMatch ? 1 : 0];
        self.regex = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:nil];
        self.invertMatch = invertMatch;
    }

    return self;
}

- (BOOL)matches:(NSString *)query
{
    NSUInteger regexMatches = [self.regex numberOfMatchesInString:query options:0 range:NSMakeRange(0, query.length)];
    
    return self.invertMatch ? (regexMatches == 0) : (regexMatches > 0);
}

@end

#endif
