// SBTMonitoredRequest.m
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

#import "SBTMonitoredRequest.h"

@implementation SBTMonitoredNetworkRequest : NSObject

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.timestamp = [[decoder decodeObjectForKey:@"timestamp"] doubleValue];
        self.requestTime = [[decoder decodeObjectForKey:@"requestTime"] doubleValue];
        self.request = [decoder decodeObjectForKey:@"request"];
        self.originalRequest = [decoder decodeObjectForKey:@"originalRequest"];
        self.response = [decoder decodeObjectForKey:@"response"];
        self.responseData = [decoder decodeObjectForKey:@"responseData"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:@(self.timestamp) forKey:@"timestamp"];
    [encoder encodeObject:@(self.requestTime) forKey:@"requestTime"];
    [encoder encodeObject:self.request forKey:@"request"];
    [encoder encodeObject:self.originalRequest forKey:@"originalRequest"];
    [encoder encodeObject:self.response forKey:@"response"];
    [encoder encodeObject:self.responseData forKey:@"responseData"];
}

- (NSString *)responseString
{
    NSString *ret = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    
    if (!ret) {
        ret = [[NSString alloc] initWithData:self.responseData encoding:NSASCIIStringEncoding];
    }
    
    return ret;
}

- (id)responseJSON
{
    NSError *error = nil;
    NSDictionary *ret = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableContainers error:&error];
    
    return (ret && !error) ? ret : nil;
}

@end

#endif
