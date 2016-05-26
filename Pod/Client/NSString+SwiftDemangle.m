// NSString+SwiftDemangle.m
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

#import "NSString+SwiftDemangle.h"

@implementation NSString (SwiftDemangle)

- (NSRange)firstRangeForRegEx:(NSString *)regEx
{
    NSRegularExpression *exp = [[NSRegularExpression alloc] initWithPattern:regEx options:NSRegularExpressionCaseInsensitive error:nil];
    NSTextCheckingResult *match = [exp firstMatchInString:self options:0 range:NSMakeRange(0, [self length])];
    
    return match.range;
}

- (NSString *)demangleSwiftClassName
{
    NSString *mangledClassName = [self copy];
    
    if ([self hasPrefix:@"_T"]) {
        // Swift class
        NSRange moduleLengthRange = [mangledClassName firstRangeForRegEx:@"\\d{1,}"];
        NSInteger moduleLength = [[mangledClassName substringWithRange:moduleLengthRange] integerValue];
        
        mangledClassName = [mangledClassName substringFromIndex:moduleLengthRange.location + moduleLengthRange.length];
        
        NSString *moduleName = [mangledClassName substringWithRange:NSMakeRange(0, moduleLength)];
        
        mangledClassName = [mangledClassName substringFromIndex:moduleName.length];
        
        NSRange classLengthRange = [mangledClassName firstRangeForRegEx:@"\\d{1,}"];
        NSInteger classLength = [[mangledClassName substringWithRange:classLengthRange] integerValue];
        
        NSString *className = [mangledClassName substringWithRange:NSMakeRange(classLengthRange.location + classLengthRange.length, classLength)];
        
        return [NSString stringWithFormat:@"%@.%@", moduleName, className];
    }

    return nil;
}

@end

#endif
