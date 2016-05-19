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

#import "SBTProxyURLProtocol.h"
#import "NSURLRequest+SBTUITestTunnelMatch.h"
#import "NSString+NSHash.h"

static NSString * const SBTProxyURLProtocolHandledKey = @"SBTProxyURLProtocolHandledKey";
static NSString * const SBTProxyURLProtocolRegexRuleKey = @"SBTProxyURLProtocolRegexRuleKey";
static NSString * const SBTProxyURLProtocolQueryRuleKey = @"SBTProxyURLProtocolQueryRuleKey";
static NSString * const SBTProxyURLProtocolDelayResponseTimeKey = @"SBTProxyURLProtocolDelayResponseTimeKey";
static NSString * const SBTProxyURLProtocolBlockKey = @"SBTProxyURLProtocolBlockKey";

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

+ (NSString *)proxyRequestsWithRegex:(NSString *)regexPattern delayResponse:(NSTimeInterval)delayResponseTime responseBlock:(void(^)(NSURLRequest *request, NSURLRequest *originalRequest, NSHTTPURLResponse *response, NSData *responseData, NSTimeInterval requestTime))block;
{
    NSDictionary *rule = @{SBTProxyURLProtocolRegexRuleKey: regexPattern, SBTProxyURLProtocolDelayResponseTimeKey: @(delayResponseTime), SBTProxyURLProtocolBlockKey: block ? [block copy] : [NSNull null]};

    [self.sharedInstance.matchingRules addObject:rule];

    return [self identifierForRule:rule];
}

+ (NSString *)proxyRequestsWithQueryParams:(NSArray<NSString *> *)queryParams delayResponse:(NSTimeInterval)delayResponseTime responseBlock:(void(^)(NSURLRequest *request, NSURLRequest *originalRequest, NSHTTPURLResponse *response, NSData *responseData, NSTimeInterval requestTime))block;
{
    NSDictionary *rule = @{SBTProxyURLProtocolQueryRuleKey: queryParams, SBTProxyURLProtocolDelayResponseTimeKey: @(delayResponseTime), SBTProxyURLProtocolBlockKey: block ? [block copy] : [NSNull null]};

    [self.sharedInstance.matchingRules addObject:rule];

    return [self identifierForRule:rule];
}

+ (BOOL)proxyRequestsRemoveWithId:(nonnull NSString *)reqId
{
    NSMutableArray *itemsToDelete = [NSMutableArray array];
    for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
        if ([[self identifierForRule:matchingRule] isEqualToString:reqId]) {
            [itemsToDelete addObject:matchingRule];
            break;
        }
    }

    [self.sharedInstance.matchingRules removeObjectsInArray:itemsToDelete];

    return NO;
}

+ (void)proxyRequestsRemoveAll
{
    self.sharedInstance.matchingRules = [NSMutableArray array];
}

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([NSURLProtocol propertyForKey:SBTProxyURLProtocolHandledKey inRequest:request]) {
        return NO;
    }

    return ([self matchingRuleForRequest:request] != nil);
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
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:SBTProxyURLProtocolHandledKey inRequest:newRequest];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    self.connection = [session dataTaskWithRequest:newRequest];

    [SBTProxyURLProtocol sharedInstance].tasksTime[@(self.connection.taskIdentifier)] = [NSDate date];

    [self.connection resume];
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
        NSDictionary *matchingRule = [SBTProxyURLProtocol matchingRuleForRequest:self.request];
        
        NSData *responseData = [SBTProxyURLProtocol sharedInstance].tasksData[@(task.taskIdentifier)];
        [[SBTProxyURLProtocol sharedInstance].tasksData removeObjectForKey:@(task.taskIdentifier)];

        __block typeof(self) weakSelf = self;
        NSTimeInterval delayResponseTime = [matchingRule[SBTProxyURLProtocolDelayResponseTimeKey] doubleValue];
        if (delayResponseTime < 0 && [self.response isKindOfClass:[NSHTTPURLResponse class]]) {
            // When negative delayResponseTime is the faked response time expressed in KB/s
            NSHTTPURLResponse *requestResponse = (NSHTTPURLResponse *)self.response;
            
            NSUInteger contentLength = [requestResponse.allHeaderFields[@"Content-Length"] unsignedIntValue];
            
            delayResponseTime = contentLength / (1024 * ABS(delayResponseTime));
        }
        
        NSTimeInterval blockDispatchTime = MAX(0.0, delayResponseTime - requestTime);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(blockDispatchTime * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [weakSelf.client URLProtocolDidFinishLoading:weakSelf];

            void(^block)(NSURLRequest *request, NSURLRequest *originalRequest, NSHTTPURLResponse *response, NSData *responseData, NSTimeInterval requestTime) = matchingRule[SBTProxyURLProtocolBlockKey];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![block isEqual:[NSNull null]]) {
                    block(weakSelf.request, task.originalRequest, (NSHTTPURLResponse *)weakSelf.response, responseData, requestTime);
                }
            });
        });

    } else {
        [self.client URLProtocol:self didFailWithError:error];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    [[SBTProxyURLProtocol sharedInstance].tasksData setObject:[[NSMutableData alloc] init] forKey:@(dataTask.taskIdentifier)];

    self.response = response;

    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];

    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    NSMutableURLRequest *mRequest = [request mutableCopy];

    [NSURLProtocol removePropertyForKey:SBTProxyURLProtocolHandledKey inRequest:mRequest];

    [self.client URLProtocol:self wasRedirectedToRequest:mRequest redirectResponse:response];

    completionHandler(mRequest);
}

#pragma mark - Helper Methods

+ (NSDictionary *)matchingRuleForRequest:(NSURLRequest *)request
{
    for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
        if ([matchingRule.allKeys containsObject:SBTProxyURLProtocolRegexRuleKey]) {
            if ([request matchesRegexPattern:matchingRule[SBTProxyURLProtocolRegexRuleKey]]) {
                return matchingRule;
            }
        } else if ([matchingRule.allKeys containsObject:SBTProxyURLProtocolQueryRuleKey]) {
            if ([request matchesQueryParams:matchingRule[SBTProxyURLProtocolQueryRuleKey]]) {
                return matchingRule;
            }
        } else {
            NSAssert(NO, @"???");
        }
    }

    return nil;
}

+ (NSString *)identifierForRule:(NSDictionary *)rule
{
    NSString *identifier = nil;
    if ([rule.allKeys containsObject:SBTProxyURLProtocolRegexRuleKey]) {
        identifier = [rule[SBTProxyURLProtocolRegexRuleKey] SHA1];
    } else if ([rule.allKeys containsObject:SBTProxyURLProtocolQueryRuleKey]) {
        NSError *error = nil;
        NSData *ruleData = [NSJSONSerialization dataWithJSONObject:rule[SBTProxyURLProtocolQueryRuleKey] options:NSJSONWritingPrettyPrinted error:&error];
        NSAssert(error == nil || !ruleData, @"???");

        identifier = [[[NSString alloc] initWithData:ruleData encoding:NSUTF8StringEncoding] SHA1];
    } else {
        NSAssert(NO, @"???");
    }

    return [@"rec-" stringByAppendingString:identifier];
}

@end