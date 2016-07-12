// SBTProxyURLProtocol.m
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

#import "SBTProxyURLProtocol.h"
#import "NSURLRequest+SBTUITestTunnelMatch.h"
#import "NSData+SHA1.h"
#import "SBTProxyStubResponse.h"

static NSString * const SBTProxyURLProtocolHandledKey = @"SBTProxyURLProtocolHandledKey";
static NSString * const SBTProxyURLProtocolRegexRuleKey = @"SBTProxyURLProtocolRegexRuleKey";
static NSString * const SBTProxyURLProtocolQueryRuleKey = @"SBTProxyURLProtocolQueryRuleKey";
static NSString * const SBTProxyURLProtocolDelayResponseTimeKey = @"SBTProxyURLProtocolDelayResponseTimeKey";
static NSString * const SBTProxyURLProtocolStubResponse = @"SBTProxyURLProtocolStubResponse";
static NSString * const SBTProxyURLProtocolBlockKey = @"SBTProxyURLProtocolBlockKey";

typedef void(^SBTProxyResponseBlock)(NSURLRequest *request, NSURLRequest *originalRequest, NSHTTPURLResponse *response, NSData *responseData, NSTimeInterval requestTime);
typedef void(^SBTStubUpdateBlock)(NSURLRequest *request);

@interface SBTProxyURLProtocol() <NSURLSessionDataDelegate,NSURLSessionTaskDelegate,NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *connection;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableData *> *tasksData;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSDate *> *tasksTime;

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *matchingRules;

@property (nonatomic, strong) NSURLResponse *response;

@end

@implementation SBTProxyURLProtocol

+ (SBTProxyURLProtocol *)sharedInstance
{
    static SBTProxyURLProtocol *sharedInstance;
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[SBTProxyURLProtocol alloc] init];
            sharedInstance.matchingRules = [NSMutableArray array];
            sharedInstance.tasksData = [NSMutableDictionary dictionary];
            sharedInstance.tasksTime = [NSMutableDictionary dictionary];
        }
    }
    
    return sharedInstance;
}

# pragma mark - Proxying

+ (NSString *)proxyRequestsWithRegex:(NSString *)regexPattern delayResponse:(NSTimeInterval)delayResponseTime responseBlock:(void(^)(NSURLRequest *request, NSURLRequest *originalRequest, NSHTTPURLResponse *response, NSData *responseData, NSTimeInterval requestTime))block;
{
    NSDictionary *rule = @{SBTProxyURLProtocolRegexRuleKey: regexPattern, SBTProxyURLProtocolDelayResponseTimeKey: @(delayResponseTime), SBTProxyURLProtocolBlockKey: block ? [block copy] : [NSNull null]};
    
    @synchronized (self.sharedInstance) {
        NSString *identifierToAdd = [self identifierForRule:rule];
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if ([[self identifierForRule:matchingRule] isEqualToString:identifierToAdd] && matchingRule[SBTProxyURLProtocolStubResponse] == nil) {
                NSLog(@"[UITestTunnelServer] Warning existing proxying request found, skipping");
                return nil;
            }
        }
        
        [self.sharedInstance.matchingRules addObject:rule];
    }
    
    return [self identifierForRule:rule];
}

+ (NSString *)proxyRequestsWithQueryParams:(NSArray<NSString *> *)queryParams delayResponse:(NSTimeInterval)delayResponseTime responseBlock:(void(^)(NSURLRequest *request, NSURLRequest *originalRequest, NSHTTPURLResponse *response, NSData *responseData, NSTimeInterval requestTime))block;
{
    NSDictionary *rule = @{SBTProxyURLProtocolQueryRuleKey: queryParams, SBTProxyURLProtocolDelayResponseTimeKey: @(delayResponseTime), SBTProxyURLProtocolBlockKey: block ? [block copy] : [NSNull null]};
    
    @synchronized (self.sharedInstance) {
        NSString *identifierToAdd = [self identifierForRule:rule];
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if ([[self identifierForRule:matchingRule] isEqualToString:identifierToAdd] && matchingRule[SBTProxyURLProtocolStubResponse] == nil) {
                NSLog(@"[UITestTunnelServer] Warning existing proxying request found, skipping");
                return nil;
            }
        }
        
        [self.sharedInstance.matchingRules addObject:rule];
    }
    
    return [self identifierForRule:rule];
}

+ (BOOL)proxyRequestsRemoveWithId:(nonnull NSString *)reqId
{
    NSMutableArray *itemsToDelete = [NSMutableArray array];
    
    @synchronized (self.sharedInstance) {
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if ([[self identifierForRule:matchingRule] isEqualToString:reqId] && matchingRule[SBTProxyURLProtocolStubResponse] == nil) {
                [itemsToDelete addObject:matchingRule];
            }
        }
        
        [self.sharedInstance.matchingRules removeObjectsInArray:itemsToDelete];
    }
    
    return itemsToDelete.count > 0;
}

+ (void)proxyRequestsRemoveAll
{
    NSMutableArray<NSString *> *itemsToDelete = [NSMutableArray array];
    
    @synchronized (self.sharedInstance) {
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if (matchingRule[SBTProxyURLProtocolStubResponse] == nil) {
                [itemsToDelete addObject:matchingRule];
            }
        }
        
        [self.sharedInstance.matchingRules removeObjectsInArray:itemsToDelete];
    }
}

#pragma mark - Stubbing

+ (NSString *)stubRequestsWithRegex:(NSString *)regexPattern stubResponse:(SBTProxyStubResponse *)stubResponse didStubRequest:(void(^)(NSURLRequest *request))block;
{
    NSDictionary *rule = @{SBTProxyURLProtocolRegexRuleKey: regexPattern, SBTProxyURLProtocolStubResponse: stubResponse, SBTProxyURLProtocolBlockKey: block ? [block copy] : [NSNull null]};
    NSString *identifierToAdd = [self identifierForRule:rule];
    
    @synchronized (self.sharedInstance) {
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if ([[self identifierForRule:matchingRule] isEqualToString:identifierToAdd] && matchingRule[SBTProxyURLProtocolStubResponse] != nil) {
                NSLog(@"[UITestTunnelServer] Warning existing stub request found, skipping");
                return nil;
            }
        }
        
        [self.sharedInstance.matchingRules addObject:rule];
    }
    
    return identifierToAdd;
}

+ (NSString *)stubRequestsWithQueryParams:(NSArray<NSString *> *)queryParams stubResponse:(SBTProxyStubResponse *)stubResponse didStubRequest:(void(^)(NSURLRequest *request))block;
{
    NSDictionary *rule = @{SBTProxyURLProtocolQueryRuleKey: queryParams, SBTProxyURLProtocolStubResponse: stubResponse, SBTProxyURLProtocolBlockKey: block ? [block copy] : [NSNull null]};
    NSString *identifierToAdd = [self identifierForRule:rule];
    
    @synchronized (self.sharedInstance) {
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if ([[self identifierForRule:matchingRule] isEqualToString:identifierToAdd] && matchingRule[SBTProxyURLProtocolStubResponse] != nil) {
                NSLog(@"[UITestTunnelServer] Warning existing stub request found, skipping");
                return nil;
            }
        }
        
        [self.sharedInstance.matchingRules addObject:rule];
    }
    
    return identifierToAdd;
}

+ (BOOL)stubRequestsRemoveWithId:(nonnull NSString *)reqId
{
    NSMutableArray *itemsToDelete = [NSMutableArray array];
    
    @synchronized (self.sharedInstance) {
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if ([[self identifierForRule:matchingRule] isEqualToString:reqId] && matchingRule[SBTProxyURLProtocolStubResponse] != nil) {
                [itemsToDelete addObject:matchingRule];
            }
        }
        
        [self.sharedInstance.matchingRules removeObjectsInArray:itemsToDelete];
    }
    
    return itemsToDelete.count > 0;
}

+ (void)stubRequestsRemoveAll
{
    @synchronized (self.sharedInstance) {
        NSMutableArray<NSString *> *itemsToDelete = [NSMutableArray array];
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if (matchingRule[SBTProxyURLProtocolStubResponse] != nil) {
                [itemsToDelete addObject:matchingRule];
            }
        }
        
        [self.sharedInstance.matchingRules removeObjectsInArray:itemsToDelete];
    }
}

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([NSURLProtocol propertyForKey:SBTProxyURLProtocolHandledKey inRequest:request]) {
        return NO;
    }
    
    return ([self matchingRulesForRequest:request] != nil);
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading
{
    NSArray<NSDictionary *> *matchingRules = [SBTProxyURLProtocol matchingRulesForRequest:self.request];
    NSDictionary *stubRule = nil;
    NSDictionary *proxyRule = nil;
    for (NSDictionary *matchingRule in matchingRules) {
        if (matchingRule[SBTProxyURLProtocolStubResponse]) {
            NSAssert(stubRule == nil, @"Multiple stubs registered for request %@!", self.request);
            stubRule = matchingRule;
        } else {
            // we can have multiple matching rule here. For example if we throttle and monitor at the same time
            proxyRule = matchingRule;
        }
    }
    
    if (stubRule) {
        // STUB REQUEST
        SBTStubUpdateBlock didStubRequestBlock = stubRule[SBTProxyURLProtocolBlockKey];
        
        SBTProxyStubResponse *stubResponse = stubRule[SBTProxyURLProtocolStubResponse];
        NSInteger stubbingStatusCode = stubResponse.statusCode;
        
        NSTimeInterval stubbingResponseTime = stubResponse.responseTime;
        if (stubbingResponseTime == 0.0 && proxyRule) {
            // if response time is not set in stub but set in proxy
            stubbingResponseTime = [proxyRule[SBTProxyURLProtocolDelayResponseTimeKey] doubleValue];
        }
        
        if (stubbingResponseTime < 0) {
            // When negative delayResponseTime is the faked response time expressed in KB/s
            stubbingResponseTime = stubResponse.data.length / (1024 * ABS(stubbingResponseTime));
        }
        
        __weak typeof(self)weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(stubbingResponseTime * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            
            NSString *length = [NSString stringWithFormat:@"%@", @(stubResponse.data.length)];
            
            NSHTTPURLResponse * response = [[NSHTTPURLResponse alloc] initWithURL:strongSelf.request.URL statusCode:stubbingStatusCode HTTPVersion:@"1.1" headerFields:stubResponse.headers];
            
            [strongSelf.client URLProtocol:strongSelf didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            [strongSelf.client URLProtocol:strongSelf didLoadData:stubResponse.data];
            [strongSelf.client URLProtocolDidFinishLoading:strongSelf];
            
            // check if the request is also proxied, we might need to manually invoke the block here
            if (proxyRule) {
                for (NSDictionary *matchingRule in matchingRules) {
                    SBTProxyResponseBlock block = matchingRule[SBTProxyURLProtocolBlockKey];
                    
                    dispatch_async(dispatch_get_main_queue(), ^() {
                        if (![block isEqual:[NSNull null]] && block != nil) {
                            block(strongSelf.request, strongSelf.request, (NSHTTPURLResponse *)response, stubResponse.data, stubbingResponseTime);
                        }
                    });
                }
            }
            
            if (![didStubRequestBlock isEqual:[NSNull null]] && didStubRequestBlock != nil) {
                didStubRequestBlock(strongSelf.request);
            }
        });
        
        return;
    }
    
    BOOL shouldProxyRequest = (matchingRules.count - (stubRule != nil) > 0);
    if (shouldProxyRequest) {
        // PROXY ONLY REQUEST (THROTTLE OR MONITORING)
        NSMutableURLRequest *newRequest = [self.request mutableCopy];
        [NSURLProtocol setProperty:@YES forKey:SBTProxyURLProtocolHandledKey inRequest:newRequest];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        self.connection = [session dataTaskWithRequest:newRequest];
        
        [SBTProxyURLProtocol sharedInstance].tasksTime[@(self.connection.taskIdentifier)] = [NSDate date];
        [SBTProxyURLProtocol sharedInstance].tasksData[@(self.connection.taskIdentifier)] = [NSMutableData data];
        
        [self.connection resume];
    }
}

- (void)stopLoading
{
    [self.connection cancel];
}

#pragma mark - NSURLSession Delegates

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
    
    NSMutableData *taskData = [[SBTProxyURLProtocol sharedInstance].tasksData objectForKey:@(dataTask.taskIdentifier)];
    [taskData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (!error) {
        NSTimeInterval requestTime = -1.0 * [[SBTProxyURLProtocol sharedInstance].tasksTime[@(task.taskIdentifier)] timeIntervalSinceNow];
        NSArray<NSDictionary *> *matchingRules = [SBTProxyURLProtocol matchingRulesForRequest:self.request];
        
        NSData *responseData = [SBTProxyURLProtocol sharedInstance].tasksData[@(task.taskIdentifier)];
        [[SBTProxyURLProtocol sharedInstance].tasksData removeObjectForKey:@(task.taskIdentifier)];
        
        NSTimeInterval delayResponseTime = [self delayResponseTime];
        
        for (NSDictionary *matchingRule in matchingRules) {
            NSTimeInterval blockDispatchTime = MAX(0.0, delayResponseTime - requestTime);
            
            __weak typeof(self)weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(blockDispatchTime * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                __strong typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf.client URLProtocolDidFinishLoading:strongSelf];
                
                SBTProxyResponseBlock block = matchingRule[SBTProxyURLProtocolBlockKey];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (![block isEqual:[NSNull null]] && block != nil) {
                        block(strongSelf.request, task.originalRequest, (NSHTTPURLResponse *)strongSelf.response, responseData, requestTime);
                    }
                });
            });
        }
    } else {
        [self.client URLProtocol:self didFailWithError:error];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    NSMutableURLRequest *mRequest = [request mutableCopy];
    
    [NSURLProtocol removePropertyForKey:SBTProxyURLProtocolHandledKey inRequest:mRequest];
    
    [self.client URLProtocol:self wasRedirectedToRequest:mRequest redirectResponse:response];
    
    completionHandler(mRequest);
}

#pragma mark - Helper Methods

- (NSTimeInterval)delayResponseTime
{
    NSTimeInterval retResponseTime = 0.0;
    NSArray<NSDictionary *> *matchingRules = [SBTProxyURLProtocol matchingRulesForRequest:self.request];
    
    for (NSDictionary *matchingRule in matchingRules) {
        NSTimeInterval delayResponseTime = [matchingRule[SBTProxyURLProtocolDelayResponseTimeKey] doubleValue];
        if (delayResponseTime < 0 && [self.response isKindOfClass:[NSHTTPURLResponse class]]) {
            // When negative delayResponseTime is the faked response time expressed in KB/s
            NSHTTPURLResponse *requestResponse = self.response;
            
            NSUInteger contentLength = [requestResponse.allHeaderFields[@"Content-Length"] unsignedIntValue];
            
            delayResponseTime = contentLength / (1024 * ABS(delayResponseTime));
        }
        
        retResponseTime = MAX(retResponseTime, delayResponseTime);
    }
    
    return retResponseTime;
}

+ (NSArray<NSDictionary *> *)matchingRulesForRequest:(NSURLRequest *)request
{
    NSMutableArray *ret = [NSMutableArray array];
    
    @synchronized (self.sharedInstance) {
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if ([matchingRule.allKeys containsObject:SBTProxyURLProtocolRegexRuleKey]) {
                if ([request matchesRegexPattern:matchingRule[SBTProxyURLProtocolRegexRuleKey]]) {
                    [ret addObject:matchingRule];
                }
            } else if ([matchingRule.allKeys containsObject:SBTProxyURLProtocolQueryRuleKey]) {
                if ([request matchesQueryParams:matchingRule[SBTProxyURLProtocolQueryRuleKey]]) {
                    [ret addObject:matchingRule];
                }
            } else {
                NSAssert(NO, @"???");
            }
        }
    }
    
    return ret.count > 0 ? ret : nil;
}

+ (NSString *)identifierForRule:(NSDictionary *)rule
{
    NSString *identifier = nil;
    if ([rule.allKeys containsObject:SBTProxyURLProtocolRegexRuleKey]) {
        NSData *ruleData = [rule[SBTProxyURLProtocolRegexRuleKey] dataUsingEncoding:NSUTF8StringEncoding];
        
        identifier = [ruleData SHA1];
    } else if ([rule.allKeys containsObject:SBTProxyURLProtocolQueryRuleKey]) {
        NSError *error = nil;
        NSData *ruleData = [NSJSONSerialization dataWithJSONObject:rule[SBTProxyURLProtocolQueryRuleKey] options:NSJSONWritingPrettyPrinted error:&error];
        NSAssert(error == nil || !ruleData, @"???");
        
        identifier = [ruleData SHA1];
    } else {
        NSAssert(NO, @"???");
    }
    
    NSString *prefix = nil;
    if (rule[SBTProxyURLProtocolStubResponse]) {
        prefix = @"stb-";
    } else if ([rule[SBTProxyURLProtocolDelayResponseTimeKey] doubleValue] > 0) {
        prefix = @"thr-";
    } else if (rule[SBTProxyURLProtocolBlockKey] && ![rule[SBTProxyURLProtocolBlockKey] isKindOfClass:[NSNull null]]) {
        prefix = @"mon-";
    }
    
    NSAssert(prefix, @"Prefix can't be nil!");
    
    return [prefix stringByAppendingString:identifier];
}

@end

#endif
