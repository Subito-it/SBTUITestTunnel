// SBTRewriteReplacement.m
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

#import "include/SBTRewriteReplacement.h"

@interface SBTRewriteReplacement ()

@property (nonnull, nonatomic, strong) NSData *findData;
@property (nonnull, nonatomic, strong) NSData *replaceData;

@end

@implementation SBTRewriteReplacement : NSObject

- (instancetype)initWithFind:(NSString *)find replace:(NSString *)replace
{
    if (self = [super init]) {
        self.findData = [find dataUsingEncoding:NSUTF8StringEncoding];
        self.replaceData = [replace dataUsingEncoding:NSUTF8StringEncoding];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.findData = [decoder decodeObjectForKey:NSStringFromSelector(@selector(findData))];
        self.replaceData = [decoder decodeObjectForKey:NSStringFromSelector(@selector(replaceData))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.findData forKey:NSStringFromSelector(@selector(findData))];
    [encoder encodeObject:self.replaceData forKey:NSStringFromSelector(@selector(replaceData))];
}

- (id)copyWithZone:(NSZone *)zone;
{
    SBTRewriteReplacement *copy = [SBTRewriteReplacement allocWithZone:zone];
    
    copy.findData = [self.findData copy];
    copy.replaceData = [self.replaceData copy];
    
    return copy;
}

- (NSString *)description
{
    NSString *ret = [NSString stringWithFormat:@"`%@` -> `%@`", [[NSString alloc] initWithData:self.findData encoding:NSUTF8StringEncoding], [[NSString alloc] initWithData:self.replaceData encoding:NSUTF8StringEncoding]];
    
    return ret;
}

- (NSString *)replace:(NSString *)string
{
    NSString *findString = [[NSString alloc] initWithData:self.findData encoding:NSUTF8StringEncoding];
    NSString *replaceString = [[NSString alloc] initWithData:self.replaceData encoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    NSRegularExpression *regexExpression = [NSRegularExpression regularExpressionWithPattern:findString options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators error:&error];
    
    NSString *replacedString = [regexExpression stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:replaceString];
    
    if (error == nil) {
        return replacedString;
    } else {
        return @"invalid-regex";
    }
}

@end
