// SBTProxyStubResponse.h
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

#import "SBTProxyStubResponse.h"

@interface SBTProxyStubResponse()

@property (nonnull, nonatomic, strong) NSData *data;
@property (nonnull, nonatomic, strong) NSDictionary<NSString *, NSString *> *headers;
@property (nonatomic, assign) NSUInteger statusCode;
@property (nonatomic, assign) NSTimeInterval responseTime;

@end

@implementation SBTProxyStubResponse

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.data = [decoder decodeObjectForKey:@"data"];
        self.headers = [decoder decodeObjectForKey:@"headers"];
        self.statusCode = [[decoder decodeObjectForKey:@"status_code"] unsignedIntegerValue];
        self.responseTime = [[decoder decodeObjectForKey:@"response_time"] doubleValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.data forKey:@"data"];
    [encoder encodeObject:self.headers forKey:@"headers"];
    [encoder encodeObject:@(self.statusCode) forKey:@"status_code"];
    [encoder encodeObject:@(self.responseTime) forKey:@"response_time"];
}

+ (nonnull SBTProxyStubResponse *)responseWithData:(nonnull NSData*)data headers:(nonnull NSDictionary<NSString *, NSString *> *)headers statusCode:(NSUInteger)statusCode responseTime:(NSTimeInterval)responseTime
{
    SBTProxyStubResponse *ret = [[SBTProxyStubResponse alloc] init];
    
    ret.data = data;
    ret.headers = headers;
    ret.statusCode = statusCode;
    ret.responseTime = responseTime;
    
    return ret;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"data-length: %lu\nstatusCode: %lu\nresponseTime: %.2f\nheaders: %@", (unsigned long)self.data.length, (unsigned long)self.statusCode, self.responseTime, self.headers];
}

@end

#endif
