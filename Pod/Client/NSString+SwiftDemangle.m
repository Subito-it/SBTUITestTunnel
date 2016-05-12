//
//  NSString+SwiftDemangle.m
//  Pods
//
//  Created by Tomas on 12/05/16.
//
//

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
