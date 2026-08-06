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

#import "private/SBTRegularExpressionMatcher.h"

static NSCache<NSString *, NSRegularExpression *> *SBTRegularExpressionCache(void)
{
    static NSCache<NSString *, NSRegularExpression *> *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
    });
    return cache;
}

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
        self.regex = [SBTRegularExpressionCache() objectForKey:pattern];
        if (self.regex == nil) {
            self.regex = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:nil];
            if (self.regex != nil) {
                [SBTRegularExpressionCache() setObject:self.regex forKey:pattern];
            }
        }
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
