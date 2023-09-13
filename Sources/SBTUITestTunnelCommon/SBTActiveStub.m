// SBTActiveStub.m
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

#import "include/SBTActiveStub.h"
#import "include/SBTRequestMatch.h"
#import "include/SBTStubResponse.h"

@implementation SBTActiveStub : NSObject

- (instancetype)initWithMatch:(SBTRequestMatch *)match response:(SBTStubResponse *)response
{
    if (self = [super init]) {
        self.match = match;
        self.response = response;
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.match = [decoder decodeObjectForKey:NSStringFromSelector(@selector(match))];
        self.response = [decoder decodeObjectForKey:NSStringFromSelector(@selector(response))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.match forKey:NSStringFromSelector(@selector(match))];
    [encoder encodeObject:self.response forKey:NSStringFromSelector(@selector(response))];
}

- (id)copyWithZone:(NSZone *)zone;
{
    SBTActiveStub *copy = [SBTActiveStub allocWithZone:zone];
    
    copy.match = [self.match copy];
    copy.response = [self.response copy];
    
    return copy;
}

@end
