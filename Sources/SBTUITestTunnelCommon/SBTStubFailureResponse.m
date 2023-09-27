// SBTStubFailureResponse.m
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

#import "include/SBTStubFailureResponse.h"

@implementation SBTStubFailureResponse

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (nonnull instancetype)initWithFailureCode:(NSInteger)failureCode
                               responseTime:(NSTimeInterval)responseTime
                           activeIterations:(NSInteger)activeIterations;
{
    if (self = [super initWithResponse:@"" headers:nil contentType:nil returnCode:-1 responseTime:responseTime activeIterations:activeIterations]) {
        self.failureCode = failureCode;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder:decoder]) {
        self.failureCode = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(failureCode))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeInteger:self.failureCode forKey:NSStringFromSelector(@selector(failureCode))];
}

- (id)copyWithZone:(NSZone *)zone;
{
    SBTStubFailureResponse *copy = [super copyWithZone:zone];
    
    copy.failureCode = self.failureCode;
   
    return copy;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if ([other isKindOfClass:[SBTStubFailureResponse class]]) {
        SBTStubFailureResponse *otherResponse = other;
        
        return self.failureCode == otherResponse.failureCode;
    } else {
        return NO;
    }
}

- (NSUInteger)hash
{
    return super.hash ^ self.failureCode;
}

@end
