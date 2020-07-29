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
    #ifndef ENABLE_UITUNNEL 
        #define ENABLE_UITUNNEL 1
    #endif
#endif

#if ENABLE_UITUNNEL

@import SBTUITestTunnelCommon;

#import "SBTProxyURLProtocol.h"

static NSString * const SBTProxyURLOriginalRequestKey = @"SBTProxyURLOriginalRequestKey";
static NSString * const SBTProxyURLProtocolHandledKey = @"SBTProxyURLProtocolHandledKey";
static NSString * const SBTProxyURLProtocolMatchingRuleKey = @"SBTProxyURLProtocolMatchingRuleKey";
static NSString * const SBTProxyURLProtocolDelayResponseTimeKey = @"SBTProxyURLProtocolDelayResponseTimeKey";
static NSString * const SBTProxyURLProtocolStubResponse = @"SBTProxyURLProtocolStubResponse";
static NSString * const SBTProxyURLProtocolRewriteResponse = @"SBTProxyURLProtocolRewriteResponse";
static NSString * const SBTProxyURLProtocolBlockCookiesKey = @"SBTProxyURLProtocolBlockCookiesKey";
static NSString * const SBTProxyURLProtocolBlockCookiesActiveIterationsKey  = @"SBTProxyURLProtocolBlockCookiesActiveIterationsKey";
static NSString * const SBTProxyURLProtocolMatchingRuleIdentifierKey = @"SBTProxyURLProtocolMatchingRuleIdentifierKey";

typedef void(^SBTStubUpdateBlock)(NSURLRequest *request);

@interface SBTProxyURLProtocol() <NSURLSessionDataDelegate,NSURLSessionTaskDelegate,NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *connection;
@property (nonatomic, strong) NSMutableDictionary<NSURLSessionTask *, NSMutableData *> *tasksData;
@property (nonatomic, strong) NSMutableDictionary<NSURLSessionTask *, NSDate *> *tasksTime;

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *matchingRules;
@property (nonatomic, strong) NSMutableArray<SBTMonitoredNetworkRequest *> *monitoredRequests;

@property (nonatomic, strong) NSURLResponse *response;

@end

@implementation SBTProxyURLProtocol

+ (SBTProxyURLProtocol *)sharedInstance
{
    static dispatch_once_t once;
    static SBTProxyURLProtocol *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[SBTProxyURLProtocol alloc] init];
        [sharedInstance reset];
    });
    return sharedInstance;
}

+ (void)reset
{
    [self.sharedInstance reset];
}

- (void)reset
{
    self.matchingRules = [NSMutableArray array];
    self.tasksData = [NSMutableDictionary dictionary];
    self.tasksTime = [NSMutableDictionary dictionary];
    self.monitoredRequests = [NSMutableArray array];
}

# pragma mark - Throttling

+ (NSString *)throttleRequestsMatching:(SBTRequestMatch *)match delayResponse:(NSTimeInterval)delayResponseTime;
{
    NSDictionary *rule = [self createRule:@{SBTProxyURLProtocolMatchingRuleKey: match,
                                            SBTProxyURLProtocolDelayResponseTimeKey: @(delayResponseTime)}];
    
    @synchronized (self.sharedInstance) {
        [self.sharedInstance.matchingRules insertObject:rule atIndex:0];
    }
    
    return rule[SBTProxyURLProtocolMatchingRuleIdentifierKey];
}

+ (BOOL)throttleRequestsRemoveWithId:(nonnull NSString *)reqId
{
    NSMutableArray *itemsToDelete = [NSMutableArray array];
    
    @synchronized (self.sharedInstance) {
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if ([matchingRule[SBTProxyURLProtocolMatchingRuleIdentifierKey] isEqualToString:reqId] && matchingRule[SBTProxyURLProtocolStubResponse] == nil) {
                [itemsToDelete addObject:matchingRule];
            }
        }
        
        [self.sharedInstance.matchingRules removeObjectsInArray:itemsToDelete];
    }
    
    return itemsToDelete.count > 0;
}

+ (void)throttleRequestsRemoveAll
{
    @synchronized (self.sharedInstance) {
        NSMutableArray<NSDictionary *> *itemsToDelete = [NSMutableArray array];
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if (matchingRule[SBTProxyURLProtocolStubResponse] == nil) {
                [itemsToDelete addObject:matchingRule];
            }
        }
        
        [self.sharedInstance.matchingRules removeObjectsInArray:itemsToDelete];
        NSLog(@"[UITestTunnelServer] %ld matching rules left", (long)self.sharedInstance.matchingRules.count);
    }
}

# pragma mark - Monitor

+ (NSString *)monitorRequestsMatching:(SBTRequestMatch *)match;
{
    NSDictionary *rule = [self createRule:@{SBTProxyURLProtocolMatchingRuleKey: match}];
    
    @synchronized (self.sharedInstance) {
        [self.sharedInstance.matchingRules insertObject:rule atIndex:0];
    }
    
    return rule[SBTProxyURLProtocolMatchingRuleIdentifierKey];
}

+ (BOOL)monitorRequestsRemoveWithId:(nonnull NSString *)reqId
{
    NSMutableArray *itemsToDelete = [NSMutableArray array];
    
    @synchronized (self.sharedInstance) {
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if ([matchingRule[SBTProxyURLProtocolMatchingRuleIdentifierKey] isEqualToString:reqId] && matchingRule[SBTProxyURLProtocolStubResponse] == nil) {
                [itemsToDelete addObject:matchingRule];
            }
        }
        
        [self.sharedInstance.matchingRules removeObjectsInArray:itemsToDelete];
    }
    
    return itemsToDelete.count > 0;
}

+ (void)monitorRequestsRemoveAll
{
    @synchronized (self.sharedInstance) {
        NSMutableArray<NSDictionary *> *itemsToDelete = [NSMutableArray array];
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if (matchingRule[SBTProxyURLProtocolStubResponse] == nil) {
                [itemsToDelete addObject:matchingRule];
            }
        }
        
        [self.sharedInstance.matchingRules removeObjectsInArray:itemsToDelete];
        NSLog(@"[UITestTunnelServer] %ld matching rules left", (long)self.sharedInstance.matchingRules.count);
    }
}

+ (NSArray<SBTMonitoredNetworkRequest *> *)monitoredRequestsAll
{
    return [self.sharedInstance.monitoredRequests copy];
}

+ (void)monitoredRequestsFlushAll
{
    [self.sharedInstance.monitoredRequests removeAllObjects];
}

#pragma mark - Stubbing

+ (NSString *)stubRequestsMatching:(SBTRequestMatch *)match stubResponse:(SBTStubResponse *)stubResponse;
{
    NSDictionary *rule = [self createRule:@{SBTProxyURLProtocolMatchingRuleKey: match,
                                            SBTProxyURLProtocolStubResponse: stubResponse}];
    
    @synchronized (self.sharedInstance) {
        [self.sharedInstance.matchingRules insertObject:rule atIndex:0];
    }
    
    return rule[SBTProxyURLProtocolMatchingRuleIdentifierKey];
}

+ (BOOL)stubRequestsRemoveWithId:(nonnull NSString *)reqId
{
    NSMutableArray *itemsToDelete = [NSMutableArray array];
    
    @synchronized (self.sharedInstance) {
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if ([matchingRule[SBTProxyURLProtocolMatchingRuleIdentifierKey] isEqualToString:reqId] && matchingRule[SBTProxyURLProtocolStubResponse] != nil) {
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
        NSMutableArray<NSDictionary *> *itemsToDelete = [NSMutableArray array];
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if (matchingRule[SBTProxyURLProtocolStubResponse] != nil) {
                [itemsToDelete addObject:matchingRule];
            }
        }
        
        [self.sharedInstance.matchingRules removeObjectsInArray:itemsToDelete];
        NSLog(@"[UITestTunnelServer] %ld matching rules left", (long)self.sharedInstance.matchingRules.count);
    }
}

+ (NSDictionary<SBTRequestMatch *, SBTStubResponse *> *)stubRequestsAll
{
    NSMutableDictionary<SBTRequestMatch *, SBTStubResponse *> *activeStubs = [NSMutableDictionary dictionary];
    
    @synchronized (self.sharedInstance) {
        NSArray<NSDictionary *> *rules = self.sharedInstance.matchingRules;
        for (NSDictionary *rule in rules) {
            SBTRequestMatch *match = rule[SBTProxyURLProtocolMatchingRuleKey];
            SBTStubResponse *response = rule[SBTProxyURLProtocolStubResponse];
            
            activeStubs[match] = response;
        }
    }
    
    return activeStubs;
}

#pragma mark - Rewrite

+ (NSString *)rewriteRequestsMatching:(SBTRequestMatch *)match rewrite:(SBTRewrite *)rewrite
{
    NSDictionary *rule = [self createRule:@{SBTProxyURLProtocolMatchingRuleKey: match,
                                            SBTProxyURLProtocolRewriteResponse: rewrite}];
    @synchronized (self.sharedInstance) {
        [self.sharedInstance.matchingRules insertObject:rule atIndex:0];
    }
    
    return rule[SBTProxyURLProtocolMatchingRuleIdentifierKey];
}

+ (BOOL)rewriteRequestsRemoveWithId:(nonnull NSString *)reqId
{
    NSMutableArray *itemsToDelete = [NSMutableArray array];
    
    @synchronized (self.sharedInstance) {
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if ([matchingRule[SBTProxyURLProtocolMatchingRuleIdentifierKey] isEqualToString:reqId] && matchingRule[SBTProxyURLProtocolRewriteResponse] != nil) {
                [itemsToDelete addObject:matchingRule];
            }
        }
        
        [self.sharedInstance.matchingRules removeObjectsInArray:itemsToDelete];
    }
    
    return itemsToDelete.count > 0;
}

+ (void)rewriteRequestsRemoveAll
{
    @synchronized (self.sharedInstance) {
        NSMutableArray<NSDictionary *> *itemsToDelete = [NSMutableArray array];
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if (matchingRule[SBTProxyURLProtocolRewriteResponse] != nil) {
                [itemsToDelete addObject:matchingRule];
            }
        }
        
        [self.sharedInstance.matchingRules removeObjectsInArray:itemsToDelete];
        NSLog(@"[UITestTunnelServer] %ld matching rules left", (long)self.sharedInstance.matchingRules.count);
    }
}

#pragma mark - Cookie Block Requests

+ (NSString *)cookieBlockRequestsMatching:(nonnull SBTRequestMatch *)match activeIterations:(NSInteger)activeIterations
{
    NSDictionary *rule = [self createRule: @{SBTProxyURLProtocolMatchingRuleKey: match,
                                             SBTProxyURLProtocolBlockCookiesKey: @(YES),
                                             SBTProxyURLProtocolBlockCookiesActiveIterationsKey: @(activeIterations)}];
    
    @synchronized (self.sharedInstance) {
        [self.sharedInstance.matchingRules insertObject:rule atIndex:0];
    }
    
    return rule[SBTProxyURLProtocolMatchingRuleIdentifierKey];
}

+ (BOOL)cookieBlockRequestsRemoveWithId:(nonnull NSString *)reqId
{
    NSMutableArray *itemsToDelete = [NSMutableArray array];
    
    @synchronized (self.sharedInstance) {
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if ([matchingRule[SBTProxyURLProtocolMatchingRuleIdentifierKey] isEqualToString:reqId] && matchingRule[SBTProxyURLProtocolBlockCookiesKey] != nil) {
                [itemsToDelete addObject:matchingRule];
            }
        }
        
        [self.sharedInstance.matchingRules removeObjectsInArray:itemsToDelete];
    }
    
    return itemsToDelete.count > 0;
}

+ (void)cookieBlockRequestsRemoveAll
{
    @synchronized (self.sharedInstance) {
        NSMutableArray<NSDictionary *> *itemsToDelete = [NSMutableArray array];
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if (matchingRule[SBTProxyURLProtocolBlockCookiesKey] != nil) {
                [itemsToDelete addObject:matchingRule];
            }
        }
        
        [self.sharedInstance.matchingRules removeObjectsInArray:itemsToDelete];
        NSLog(@"[UITestTunnelServer] %ld matching rules left", (long)self.sharedInstance.matchingRules.count);
    }
}

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    // Note #1: this method can be called internally multiple times for the same request
    // Note #2: it is not guaranteed that request that is being passed contains the expected
    // values for the allHTTPHeaderFields property in one of these iterations. For this
    // reason we postpone matching the request headers after startLoading is called.
    
    if ([NSURLProtocol propertyForKey:SBTProxyURLProtocolHandledKey inRequest:request]) {
        return NO;
    }
        
    NSArray *matchingRules = [self matchingRulesForRequest:request];
    return (matchingRules != nil);
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    BOOL isCacheEquivalent = [super requestIsCacheEquivalent:a toRequest:b];
    return isCacheEquivalent;
}

- (void)startLoading
{
    NSArray<NSDictionary *> *matchingRules = [SBTProxyURLProtocol matchingRulesForRequest:self.request];
    NSDictionary *stubRule = nil;
    NSDictionary *proxyRule = nil;
    NSDictionary *cookieBlockRule = nil;
    NSDictionary *rewriteRule = nil;
    
    for (NSDictionary *matchingRule in matchingRules) {
        // Note that we only consider the first instance found for each rule type. We want to "skip" other instances which could be evaluated in future calls.
        if (matchingRule[SBTProxyURLProtocolStubResponse]) {
            if (stubRule == nil) {
                stubRule = matchingRule;
            }
        } else if (matchingRule[SBTProxyURLProtocolRewriteResponse]) {
            if (rewriteRule == nil) {
                rewriteRule = matchingRule;
            }
        } else if (matchingRule[SBTProxyURLProtocolBlockCookiesKey]) {
            if (cookieBlockRule == nil) {
                cookieBlockRule = matchingRule;
            }
        } else {
            // we can have multiple matching rule here. For example if we throttle and monitor at the same time
            // TODO: should check for (proxyRule == nil) here? (I cannot fully understand the comment...)
            proxyRule = matchingRule;
        }
    }
    
    SBTRequestMatch *requestMatch = stubRule[SBTProxyURLProtocolMatchingRuleKey];
    BOOL stubbingHeaders = requestMatch.requestHeaders != nil || requestMatch.responseHeaders != nil;
    
    if (stubRule && !stubbingHeaders) {
        // STUB REQUEST
        SBTStubResponse *stubResponse = stubRule[SBTProxyURLProtocolStubResponse];
        NSInteger stubbingStatusCode = stubResponse.returnCode;
        
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
        id<NSURLProtocolClient>client = self.client;
        NSURLRequest *request = self.request;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(stubbingResponseTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            
            strongSelf.response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:stubbingStatusCode HTTPVersion:nil headerFields:stubResponse.headers];
            
            if ([strongSelf monitorRuleForCurrentRequest] != nil) {
                SBTMonitoredNetworkRequest *monitoredRequest = [[SBTMonitoredNetworkRequest alloc] init];
                
                monitoredRequest.timestamp = [[NSDate date] timeIntervalSinceReferenceDate];
                monitoredRequest.requestTime = stubbingResponseTime;
                monitoredRequest.request = strongSelf.request;
                monitoredRequest.originalRequest = strongSelf.request;
                
                monitoredRequest.response = (NSHTTPURLResponse *)strongSelf.response;
                
                monitoredRequest.responseData = stubResponse.data;
                
                monitoredRequest.isStubbed = YES;
                monitoredRequest.isRewritten = NO;
                
                [[SBTProxyURLProtocol sharedInstance].monitoredRequests addObject:monitoredRequest];
            }
            
            if ([stubResponse isKindOfClass:[SBTStubFailureResponse class]]) {
                SBTStubFailureResponse *failureStubResponse = (SBTStubFailureResponse *)stubResponse;
                NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:failureStubResponse.failureCode userInfo:nil];
                
                [client URLProtocol:strongSelf didFailWithError:error];
                [client URLProtocolDidFinishLoading:strongSelf];
            } else {
                if (stubResponse.headers[@"Location"] != nil) {
                    NSURL *redirectionUrl = [NSURL URLWithString:stubResponse.headers[@"Location"]];
                    NSMutableURLRequest *redirectionRequest = [NSMutableURLRequest requestWithURL:redirectionUrl];
                    
                    [NSURLProtocol removePropertyForKey:SBTProxyURLProtocolHandledKey inRequest:redirectionRequest];
                    if (![NSURLProtocol propertyForKey:SBTProxyURLOriginalRequestKey inRequest:redirectionRequest]) {
                        // don't handle double (or more) redirects
                        [NSURLProtocol setProperty:request forKey:SBTProxyURLOriginalRequestKey inRequest:redirectionRequest];
                    }
                    
                    [client URLProtocol:strongSelf wasRedirectedToRequest:redirectionRequest redirectResponse:strongSelf.response];
                } else {
                    [client URLProtocol:strongSelf didReceiveResponse:strongSelf.response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
                    [client URLProtocol:strongSelf didLoadData:stubResponse.data];
                    [client URLProtocolDidFinishLoading:strongSelf];
                }
            }
            
            if (stubResponse.activeIterations > 0) {
                if (--stubResponse.activeIterations == 0) {
                    [SBTProxyURLProtocol stubRequestsRemoveWithId:stubRule[SBTProxyURLProtocolMatchingRuleIdentifierKey]];
                }
            }
        });
        
        return;
    }
    
    if (proxyRule != nil || rewriteRule != nil || cookieBlockRule != nil || stubbingHeaders) {
        __unused SBTRequestMatch *requestMatch1 = proxyRule[SBTProxyURLProtocolMatchingRuleKey];
        __unused SBTRequestMatch *requestMatch2 = cookieBlockRule[SBTProxyURLProtocolMatchingRuleKey];
        __unused SBTRequestMatch *requestMatch3 = rewriteRule[SBTProxyURLProtocolMatchingRuleKey];
        __unused SBTRequestMatch *requestMatch4 = stubRule[SBTProxyURLProtocolMatchingRuleKey];
        NSLog(@"[UITestTunnelServer] Throttling/monitoring/chaning cookies/stubbing headers %@ request: %@\n\nMatching rule:\n%@", [self.request HTTPMethod], [self.request URL], requestMatch1 ?: requestMatch2 ?: requestMatch3 ?: requestMatch4);
        
        NSMutableURLRequest *newRequest = [self.request mutableCopy];
        [NSURLProtocol setProperty:@YES forKey:SBTProxyURLProtocolHandledKey inRequest:newRequest];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        
        if (cookieBlockRule != nil) {
            [newRequest addValue:@"" forHTTPHeaderField:@"Cookie"];
            NSInteger cookieBlockActiveIterations = [cookieBlockRule[SBTProxyURLProtocolBlockCookiesActiveIterationsKey] integerValue];
            
            if (--cookieBlockActiveIterations == 0) {
                [SBTProxyURLProtocol cookieBlockRequestsRemoveWithId:cookieBlockRule[SBTProxyURLProtocolMatchingRuleIdentifierKey]];
            } else {
                //cookieBlockRule[SBTProxyURLProtocolBlockCookiesActiveIterationsKey] = @(cookieBlockActiveIterations);
            }
        } else {
            [self moveCookiesToHeader:newRequest];
        }
        
        SBTRewrite *rewrite = [self rewriteRuleForCurrentRequest][SBTProxyURLProtocolRewriteResponse];
        if (rewrite != nil) {
            newRequest.URL = [rewrite rewriteUrl:newRequest.URL];
            newRequest.allHTTPHeaderFields = [rewrite rewriteRequestHeaders:newRequest.allHTTPHeaderFields];
            newRequest.HTTPBody = [rewrite rewriteRequestBody:newRequest.HTTPBody];
        }
        
        self.connection = [session dataTaskWithRequest:newRequest];
        
        [SBTProxyURLProtocol sharedInstance].tasksTime[self.connection] = [NSDate date];
        [SBTProxyURLProtocol sharedInstance].tasksData[self.connection] = [NSMutableData data];
        
        [self.connection resume];
    }
}

- (void)stopLoading
{
    [self.connection cancel];
}

- (void)moveCookiesToHeader:(NSMutableURLRequest *)newRequest
{
    // Move cookies from storage to headers, useful to properly extract cookies when monitoring requests
    NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:newRequest.URL];
    
    if (cookies.count > 0) {
        // instead of calling [newRequest addValue:forHTTPHeaderField:] multiple times
        // https://stackoverflow.com/questions/16305814/are-multiple-cookie-headers-allowed-in-an-http-request
        NSMutableString *multipleCookieString = [NSMutableString string];
        for (NSHTTPCookie* cookie in cookies) {
            [multipleCookieString appendFormat:@"%@=%@;", cookie.name, cookie.value];
        }
        
        [newRequest setValue:multipleCookieString forHTTPHeaderField:@"Cookie"];
    }
}

#pragma mark - NSURLSession Delegates

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    if ([self rewriteRuleForCurrentRequest] != nil) {
        // if we're rewriting the request we will send only a didLoadData callback after rewriting content once everything was received
    } else {
        [self.client URLProtocol:self didLoadData:data];
    }
    
    NSMutableData *taskData = [[SBTProxyURLProtocol sharedInstance].tasksData objectForKey:dataTask];
    NSAssert(taskData != nil, @"Should not be nil");
    [taskData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSURLRequest *request = self.request;
    NSDictionary *rewriteRule = [self rewriteRuleForCurrentRequest];
    BOOL isRequestRewritten = (rewriteRule != nil);
    
    NSTimeInterval requestTime = -1.0 * [[SBTProxyURLProtocol sharedInstance].tasksTime[task] timeIntervalSinceNow];
        
    NSData *responseData = [[SBTProxyURLProtocol sharedInstance].tasksData objectForKey:task];
    NSAssert(responseData != nil, @"Should not be nil");
    [[SBTProxyURLProtocol sharedInstance].tasksData removeObjectForKey:task];
    
    self.response = task.response;
    
    if (isRequestRewritten) {
        SBTRewrite *rewrite = rewriteRule[SBTProxyURLProtocolRewriteResponse];
        responseData = [rewrite rewriteResponseBody:responseData];
        NSHTTPURLResponse *taskResponse = (NSHTTPURLResponse *)task.response;
        if ([taskResponse isKindOfClass:[NSHTTPURLResponse class]]) {
            NSDictionary *headers = [rewrite rewriteResponseHeaders:taskResponse.allHeaderFields];
            NSInteger statusCode = [rewrite rewriteStatusCode:taskResponse.statusCode];
            self.response = [[NSHTTPURLResponse alloc] initWithURL:taskResponse.URL statusCode:statusCode HTTPVersion:nil headerFields:headers];
        }
        
        if (--rewrite.activeIterations == 0) {
            [SBTProxyURLProtocol rewriteRequestsRemoveWithId:rewriteRule[SBTProxyURLProtocolMatchingRuleIdentifierKey]];
        }
    }
    
    NSTimeInterval delayResponseTime = [self delayResponseTime];
    NSTimeInterval blockDispatchTime = MAX(0.0, delayResponseTime - requestTime);
    
    __weak typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(blockDispatchTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        NSURLRequest *originalRequest = [NSURLProtocol propertyForKey:SBTProxyURLOriginalRequestKey inRequest:request];
        
        if ([strongSelf monitorRuleForCurrentRequest] != nil) {
            SBTMonitoredNetworkRequest *monitoredRequest = [[SBTMonitoredNetworkRequest alloc] init];
            
            monitoredRequest.timestamp = [[NSDate date] timeIntervalSinceReferenceDate];
            monitoredRequest.requestTime = requestTime;
            monitoredRequest.request = request ?: task.currentRequest;
            monitoredRequest.originalRequest = originalRequest ?: task.originalRequest;
            
            monitoredRequest.response = (NSHTTPURLResponse *)strongSelf.response;
            
            monitoredRequest.responseData = responseData;
            
            monitoredRequest.isStubbed = NO;
            monitoredRequest.isRewritten = isRequestRewritten;
            
            [[SBTProxyURLProtocol sharedInstance].monitoredRequests addObject:monitoredRequest];
        }
        
        if (isRequestRewritten) {
            [weakSelf.client URLProtocol:weakSelf didReceiveResponse:strongSelf.response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            [weakSelf.client URLProtocol:weakSelf didLoadData:responseData];
        }
        
        if (error) {
            [weakSelf.client URLProtocol:self didFailWithError:error];
        } else {
            [weakSelf.client URLProtocolDidFinishLoading:strongSelf];
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    NSMutableURLRequest *mRequest = [request mutableCopy];
    
    [NSURLProtocol removePropertyForKey:SBTProxyURLProtocolHandledKey inRequest:mRequest];
    if (![NSURLProtocol propertyForKey:SBTProxyURLOriginalRequestKey inRequest:mRequest]) {
        // don't handle double (or more) redirects
        [NSURLProtocol setProperty:self.request forKey:SBTProxyURLOriginalRequestKey inRequest:mRequest];
    }
    
    [self.client URLProtocol:self wasRedirectedToRequest:mRequest redirectResponse:response];
    
    completionHandler(mRequest);
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSDictionary *headersStubRequest = [self stubRuleForCurrentRequest];
    if ([self rewriteRuleForCurrentRequest] != nil) {
        // if we're rewriting the request we will send only a didReceiveResponse callback after rewriting content once everything was received
    } else if (headersStubRequest != nil) {
        SBTRequestMatch *requestMatch = headersStubRequest[SBTProxyURLProtocolMatchingRuleKey];
        
        BOOL headersMatch = YES;
        
        NSDictionary *requestHeaders = dataTask.currentRequest.allHTTPHeaderFields ?: @{};
        if (requestMatch.requestHeaders.count > 0) {
            headersMatch &= [requestMatch matchesRequestHeaders:requestHeaders];
        }
        
        NSDictionary *responseHeaders = @{};
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            responseHeaders = ((NSHTTPURLResponse *)response).allHeaderFields;
            
            headersMatch &= [requestMatch matchesResponseHeaders:responseHeaders];
        }
        
        SBTStubResponse *stubResponse = headersStubRequest[SBTProxyURLProtocolStubResponse];
        
        if (stubResponse.activeIterations > 0) {
            if (--stubResponse.activeIterations == 0) {
                [SBTProxyURLProtocol stubRequestsRemoveWithId:headersStubRequest[SBTProxyURLProtocolMatchingRuleIdentifierKey]];
            }
        }
        
        if (headersMatch) {
            [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            [self.client URLProtocol:self didLoadData:stubResponse.data];
            [self.client URLProtocolDidFinishLoading:self];

            return;
        } else {
            [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        }
    } else {
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    }
    
    completionHandler(NSURLSessionResponseAllow);
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
            NSHTTPURLResponse *requestResponse = (NSHTTPURLResponse *)self.response;
            
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
            if ([matchingRule.allKeys containsObject:SBTProxyURLProtocolMatchingRuleKey]) {
                NSURLRequest *originalRequest = [NSURLProtocol propertyForKey:SBTProxyURLOriginalRequestKey inRequest:request];
                
                SBTRequestMatch *match = matchingRule[SBTProxyURLProtocolMatchingRuleKey];
                if ([match matchesURLRequest:originalRequest ?: request]) {
                    [ret addObject:matchingRule];
                }
            } else {
                NSAssert(NO, @"???");
            }
        }
    }
    
    return ret.count > 0 ? ret : nil;
}

+ (NSDictionary *)createRule:(NSDictionary *)attributes
{
    NSString *prefix = nil;
    if (attributes[SBTProxyURLProtocolStubResponse]) {
        prefix = @"stb-";
    } else if (attributes[SBTProxyURLProtocolBlockCookiesKey]) {
        prefix = @"coo-";
    } else if (attributes[SBTProxyURLProtocolDelayResponseTimeKey]) {
        prefix = @"thr-";
    } else if (attributes[SBTProxyURLProtocolRewriteResponse]) {
        prefix = @"rwr-";
    } else {
        prefix = @"mon-";
    }
    
    NSAssert(prefix, @"Prefix can't be nil!");
    
    NSMutableDictionary *rule = [NSMutableDictionary dictionaryWithDictionary:attributes];
    rule[SBTProxyURLProtocolMatchingRuleIdentifierKey] = [prefix stringByAppendingString:[[NSUUID UUID] UUIDString]];
    return rule;
}

- (NSDictionary *)rewriteRuleForCurrentRequest
{
    NSArray<NSDictionary *> *matchingRules = [SBTProxyURLProtocol matchingRulesForRequest:self.request];
    for (NSDictionary *matchingRule in matchingRules) {
        if (matchingRule[SBTProxyURLProtocolRewriteResponse] != nil) {
            return matchingRule;
        }
    }
    
    return nil;
}

- (NSDictionary *)stubRuleForCurrentRequest
{
    NSArray<NSDictionary *> *matchingRules = [SBTProxyURLProtocol matchingRulesForRequest:self.request];
    for (NSDictionary *matchingRule in matchingRules) {
        if (matchingRule[SBTProxyURLProtocolStubResponse] != nil) {
            return matchingRule;
        }
    }
    
    return nil;
}

- (NSDictionary *)monitorRuleForCurrentRequest
{
    NSArray<NSDictionary *> *matchingRules = [SBTProxyURLProtocol matchingRulesForRequest:self.request];
    for (NSDictionary *matchingRule in matchingRules) {
        if (matchingRule[SBTProxyURLProtocolStubResponse] == nil && matchingRule[SBTProxyURLProtocolDelayResponseTimeKey] == nil && matchingRule[SBTProxyURLProtocolRewriteResponse] == nil) {
            return matchingRule;
        }
    }
    
    return nil;
}

@end

#endif

