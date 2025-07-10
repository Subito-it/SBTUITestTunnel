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
@property (nonatomic, strong) dispatch_queue_t monitoredRequestsSyncQueue;

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
    self.monitoredRequestsSyncQueue = dispatch_queue_create("com.sbtuitesttunnel.protocol.queue", DISPATCH_QUEUE_SERIAL);
}

# pragma mark - Throttling

+ (NSString *)throttleRequestsMatching:(SBTRequestMatch *)match delayResponse:(NSTimeInterval)delayResponseTime;
{
    NSDictionary *rule = [self makeRuleWithAttributes:@{SBTProxyURLProtocolMatchingRuleKey: match,
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
        NSLog(@"[SBTUITestTunnel] %ld matching rules left", (long)self.sharedInstance.matchingRules.count);
    }
}

# pragma mark - Monitor

+ (NSString *)monitorRequestsMatching:(SBTRequestMatch *)match;
{
    NSDictionary *rule = [self makeRuleWithAttributes:@{SBTProxyURLProtocolMatchingRuleKey: match}];
    
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
        NSLog(@"[SBTUITestTunnel] %ld matching rules left", (long)self.sharedInstance.matchingRules.count);
    }
}

+ (NSArray<SBTMonitoredNetworkRequest *> *)monitoredRequestsAll
{
    __block NSArray<SBTMonitoredNetworkRequest *> *ret;
    dispatch_sync(self.sharedInstance.monitoredRequestsSyncQueue, ^{
        ret = [self.sharedInstance.monitoredRequests copy];
    });
    
    return ret;
}

+ (void)monitoredRequestsFlushAll
{
    dispatch_sync(self.sharedInstance.monitoredRequestsSyncQueue, ^{
        [self.sharedInstance.monitoredRequests removeAllObjects];
    });
}

#pragma mark - Stubbing

+ (NSString *)stubRequestsMatching:(SBTRequestMatch *)match stubResponse:(SBTStubResponse *)stubResponse;
{
    NSDictionary *rule = [self makeRuleWithAttributes:@{SBTProxyURLProtocolMatchingRuleKey: match,
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

+ (BOOL)stubRequestsRemoveWithRequestMatch:(nonnull SBTRequestMatch *)match
{
    NSMutableArray *itemsToDelete = [NSMutableArray array];
    
    @synchronized (self.sharedInstance) {
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if ([matchingRule[SBTProxyURLProtocolMatchingRuleKey] isEqual:match] && matchingRule[SBTProxyURLProtocolStubResponse] != nil) {
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
        NSLog(@"[SBTUITestTunnel] %ld matching rules left", (long)self.sharedInstance.matchingRules.count);
    }
}


+ (NSArray<SBTActiveStub *>*)stubRequestsAll
{
    NSMutableArray<SBTActiveStub *> *activeStubs = [NSMutableArray array];
    
    @synchronized (self.sharedInstance) {
        NSArray<NSDictionary *> *rules = self.sharedInstance.matchingRules;
        for (NSDictionary *rule in rules) {
            SBTRequestMatch *match = rule[SBTProxyURLProtocolMatchingRuleKey];
            SBTStubResponse *response = rule[SBTProxyURLProtocolStubResponse];
            
            SBTActiveStub *activeStub = [[SBTActiveStub alloc] initWithMatch:match response:response];
            [activeStubs addObject:activeStub];
        }
    }
    
    return activeStubs;
}

#pragma mark - Rewrite

+ (NSString *)rewriteRequestsMatching:(SBTRequestMatch *)match rewrite:(SBTRewrite *)rewrite
{
    NSDictionary *rule = [self makeRuleWithAttributes:@{SBTProxyURLProtocolMatchingRuleKey: match,
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
        NSLog(@"[SBTUITestTunnel] %ld matching rules left", (long)self.sharedInstance.matchingRules.count);
    }
}

#pragma mark - Cookie Block Requests

+ (NSString *)cookieBlockRequestsMatching:(nonnull SBTRequestMatch *)match activeIterations:(NSInteger)activeIterations
{
    NSDictionary *rule = [self makeRuleWithAttributes: @{SBTProxyURLProtocolMatchingRuleKey: match,
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
        NSLog(@"[SBTUITestTunnel] %ld matching rules left", (long)self.sharedInstance.matchingRules.count);
    }
}

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    // Note #1: this method can be called internally multiple times for the same request
    // Note #2: it is not guaranteed that request that is being passed contains the expected
    // values for the allHTTPHeaderFields property in one of these callse. For this reason
    // we postpone matching the request headers after startLoading is called.
    
    if (![request.URL.scheme hasPrefix:@"http"]) {
        // SBTURLProtocol only supports HTTP requests (not WebSocket, for example)
        return NO;
    }
        
    if ([SBTRequestPropertyStorage propertyForKey:SBTProxyURLProtocolHandledKey inRequest:request]) {
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
    NSDictionary *stubRule = [self stubRuleFromMatchingRules:matchingRules];
    NSDictionary *throttleRule = [self throttleRuleFromMatchingRules:matchingRules];
    NSDictionary *cookieBlockRule = [self blockCookieRuleFromMatchingRules:matchingRules];
    NSDictionary *rewriteRule = [self rewriteRuleFromMatchingRules:matchingRules];
    NSDictionary *monitorRule = [self monitorRuleFromMatchingRules:matchingRules];
    
    SBTRequestMatch *requestMatch = stubRule[SBTProxyURLProtocolMatchingRuleKey];
    BOOL stubbingHeaders = requestMatch.requestHeaders != nil || requestMatch.responseHeaders != nil;
    
    if (stubRule && !stubbingHeaders) {
        // STUB REQUEST
        SBTStubResponse *stubResponse = stubRule[SBTProxyURLProtocolStubResponse];
        NSInteger stubbingStatusCode = stubResponse.returnCode;
                
        NSTimeInterval stubbingResponseTime = stubResponse.responseTime;
        if (stubbingResponseTime == 0.0 && throttleRule) {
            // if response time is not set in stub but set in proxy
            stubbingResponseTime = [throttleRule[SBTProxyURLProtocolDelayResponseTimeKey] doubleValue];
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
            
            if ([strongSelf monitorRuleFromMatchingRules:matchingRules] != nil) {
                SBTMonitoredNetworkRequest *monitoredRequest = [[SBTMonitoredNetworkRequest alloc] init];
                
                monitoredRequest.timestamp = [[NSDate date] timeIntervalSinceReferenceDate];
                monitoredRequest.requestTime = stubbingResponseTime;
                monitoredRequest.request = strongSelf.request;
                monitoredRequest.originalRequest = strongSelf.request;
                
                monitoredRequest.response = (NSHTTPURLResponse *)strongSelf.response;
                
                monitoredRequest.responseData = stubResponse.data;
                
                monitoredRequest.isStubbed = YES;
                monitoredRequest.isRewritten = NO;
            
                
                monitoredRequest.requestData = [monitoredRequest.originalRequest sbt_extractHTTPBody];
                
                dispatch_sync([SBTProxyURLProtocol sharedInstance].monitoredRequestsSyncQueue, ^{
                    [[SBTProxyURLProtocol sharedInstance].monitoredRequests addObject:monitoredRequest];
                });
            }
            
            if ([stubResponse isKindOfClass:[SBTStubFailureResponse class]]) {
                SBTStubFailureResponse *failureStubResponse = (SBTStubFailureResponse *)stubResponse;
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:failureStubResponse.failureCode userInfo:nil];
                
                [client URLProtocol:strongSelf didFailWithError:error];
                [client URLProtocolDidFinishLoading:strongSelf];
            } else {
                if (stubResponse.headers[@"Location"] != nil) {
                    NSURL *redirectionUrl = [NSURL URLWithString:stubResponse.headers[@"Location"]];
                    NSMutableURLRequest *redirectionRequest = [NSMutableURLRequest requestWithURL:redirectionUrl];
                    
                    [NSURLProtocol removePropertyForKey:SBTProxyURLProtocolHandledKey inRequest:redirectionRequest];
                    if (![SBTRequestPropertyStorage propertyForKey:SBTProxyURLOriginalRequestKey inRequest:redirectionRequest]) {
                        // don't handle double (or more) redirects
                        [[self class] associateOriginalRequest:request withRequest:redirectionRequest];
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
    
    if (monitorRule != nil || throttleRule != nil || rewriteRule != nil || cookieBlockRule != nil || stubbingHeaders) {
        __unused SBTRequestMatch *requestMatch1 = throttleRule[SBTProxyURLProtocolMatchingRuleKey];
        __unused SBTRequestMatch *requestMatch2 = cookieBlockRule[SBTProxyURLProtocolMatchingRuleKey];
        __unused SBTRequestMatch *requestMatch3 = rewriteRule[SBTProxyURLProtocolMatchingRuleKey];
        __unused SBTRequestMatch *requestMatch4 = stubRule[SBTProxyURLProtocolMatchingRuleKey];
        __unused SBTRequestMatch *requestMatch5 = monitorRule[SBTProxyURLProtocolMatchingRuleKey];
        NSLog(@"[SBTUITestTunnel] Throttling/monitoring/chaning cookies/stubbing headers %@ request: %@\n\nMatching rule:\n%@", [self.request HTTPMethod], [self.request URL], requestMatch1 ?: requestMatch2 ?: requestMatch3 ?: requestMatch4 ?: requestMatch5);
        NSMutableURLRequest *newRequest = [self.request mutableCopy];
        NSData *bodyData = [self.request sbt_extractHTTPBody];
        if (bodyData) {
            [newRequest setHTTPBody:bodyData];
            [newRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)bodyData.length]
                 forHTTPHeaderField:@"Content-Length"];
        }
        
        [SBTRequestPropertyStorage setProperty:@YES forKey:SBTProxyURLProtocolHandledKey inRequest:newRequest];
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        #if TARGET_OS_SIMULATOR
        if (@available(iOS 13.0, *)) {
            // This is a workaround as per https://developer.apple.com/forums/thread/777999
            configuration.TLSMaximumSupportedProtocolVersion = tls_protocol_version_TLSv12;
        }
        #endif
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        
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
        
        SBTRewrite *rewrite = [self rewriteRuleFromMatchingRules:matchingRules][SBTProxyURLProtocolRewriteResponse];
        if (rewrite != nil) {
            newRequest.URL = [rewrite rewriteUrl:newRequest.URL];
            // Starting from iOS 18.x, NSURLRequest.allHTTPHeaderFields appears to be a computed property.
            // It is no longer possible to replace its content in place: setting newRequest.allHTTPHeaderFields = @{} does not clear the headers,
            // and assigning a new dictionary (e.g., newRequest.allHTTPHeaderFields = @{ @"new_key": @"new_value" }) simply adds or updates keys
            // instead of replacing all headers. To fully reset and replace headers, you need to separately remove headers using
            // [newRequest setValue:nil forHTTPHeaderField:] for each key, and then set the new headers.
            for (NSString *key in rewrite.requestHeadersReplacement) {
                NSString *value = rewrite.requestHeadersReplacement[key];
                if (value.length == 0) {
                    [newRequest setValue:nil forHTTPHeaderField:key];
                }
            }
            newRequest.allHTTPHeaderFields = [rewrite rewriteRequestHeaders:newRequest.allHTTPHeaderFields];;
            newRequest.HTTPBody = [rewrite rewriteRequestBody:newRequest.HTTPBody];
        }
        
        self.connection = [session dataTaskWithRequest:newRequest];
        
        [SBTProxyURLProtocol sharedInstance].tasksTime[self.connection] = [NSDate date];
        [SBTProxyURLProtocol sharedInstance].tasksData[self.connection] = [NSMutableData data];
        
        NSTimeInterval delayResponseTime = [self delayResponseTime];
        __weak typeof(self)weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayResponseTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.connection resume];
        });
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
    NSArray<NSDictionary *> *matchingRules = [SBTProxyURLProtocol matchingRulesForRequest:self.request];
    if ([self rewriteRuleFromMatchingRules:matchingRules] != nil) {
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
    NSArray<NSDictionary *> *matchingRules = [SBTProxyURLProtocol matchingRulesForRequest:self.request];
    NSURLRequest *request = self.request;
    NSDictionary *rewriteRule = [self rewriteRuleFromMatchingRules:matchingRules];
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
    
    NSURLRequest *originalRequest = [[self class] originalRequestFor:request];
    
    if ([self monitorRuleFromMatchingRules:matchingRules] != nil) {
        SBTMonitoredNetworkRequest *monitoredRequest = [[SBTMonitoredNetworkRequest alloc] init];
        
        monitoredRequest.timestamp = [[NSDate date] timeIntervalSinceReferenceDate];
        monitoredRequest.requestTime = requestTime;
        monitoredRequest.request = request ?: task.currentRequest;
        monitoredRequest.originalRequest = originalRequest ?: task.originalRequest;
        
        monitoredRequest.response = (NSHTTPURLResponse *)self.response;
        
        monitoredRequest.responseData = responseData;
        
        monitoredRequest.isStubbed = NO;
        monitoredRequest.isRewritten = isRequestRewritten;
        
        monitoredRequest.requestData = [monitoredRequest.originalRequest sbt_extractHTTPBody];
        
        dispatch_sync([SBTProxyURLProtocol sharedInstance].monitoredRequestsSyncQueue, ^{
            [[SBTProxyURLProtocol sharedInstance].monitoredRequests addObject:monitoredRequest];
        });
    }
    
    if (isRequestRewritten) {
        [self.client URLProtocol:self didReceiveResponse:self.response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:responseData];
    }
    
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    NSMutableURLRequest *mRequest = [request mutableCopy];
    if (response.statusCode == 302 || response.statusCode == 303) {
        mRequest.HTTPBody = [NSData data]; // GET redirects should not forward HTTPBody
    }
    
    [NSURLProtocol removePropertyForKey:SBTProxyURLProtocolHandledKey inRequest:mRequest];
    if (![SBTRequestPropertyStorage propertyForKey:SBTProxyURLOriginalRequestKey inRequest:mRequest]) {
        // don't handle double (or more) redirects
        [[self class] associateOriginalRequest:self.request withRequest:mRequest];
    }
    
    [self.client URLProtocol:self wasRedirectedToRequest:mRequest redirectResponse:response];
    
    completionHandler(mRequest);
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSArray<NSDictionary *> *matchingRules = [SBTProxyURLProtocol matchingRulesForRequest:self.request];
    NSDictionary *headersStubRequest = [self stubRuleFromMatchingRules:matchingRules];
    if ([self rewriteRuleFromMatchingRules:matchingRules] != nil) {
        // if we're rewriting the request we will send only a didReceiveResponse callback after rewriting content once everything was received
    } else if (headersStubRequest != nil) {
        SBTRequestMatch *requestMatch = headersStubRequest[SBTProxyURLProtocolMatchingRuleKey];
        
        BOOL headersMatch = YES;
        
        NSDictionary *requestHeaders = dataTask.currentRequest.allHTTPHeaderFields ?: @{};
        if (requestMatch.requestHeaders.count > 0) {
            headersMatch &= [requestMatch matchesRequestHeaders:requestHeaders];
        }
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSDictionary *responseHeaders = ((NSHTTPURLResponse *)response).allHeaderFields;
            
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
    NSArray<NSDictionary *> *matchingRules = [SBTProxyURLProtocol matchingRulesForRequest:self.request];
    NSTimeInterval retResponseTime = 0.0;
    NSDictionary *throttleRule = [self throttleRuleFromMatchingRules:matchingRules];

    NSTimeInterval delayResponseTime = [throttleRule[SBTProxyURLProtocolDelayResponseTimeKey] doubleValue];
    if (delayResponseTime < 0 && [self.response isKindOfClass:[NSHTTPURLResponse class]]) {
        // When negative delayResponseTime is the faked response time expressed in KB/s
        NSHTTPURLResponse *requestResponse = (NSHTTPURLResponse *)self.response;
        
        NSUInteger contentLength = [requestResponse.allHeaderFields[@"Content-Length"] unsignedIntValue];
        delayResponseTime = contentLength / (1024 * ABS(delayResponseTime));
    }

    return MAX(retResponseTime, delayResponseTime);
}

+ (NSArray<NSDictionary *> *)matchingRulesForRequest:(NSURLRequest *)request
{
    NSMutableArray *ret = [NSMutableArray array];
    
    @synchronized (self.sharedInstance) {
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            if ([matchingRule.allKeys containsObject:SBTProxyURLProtocolMatchingRuleKey]) {
                NSURLRequest *originalRequest = [self originalRequestFor:request];
                
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

+ (NSDictionary *)makeRuleWithAttributes:(NSDictionary *)attributes
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

- (NSDictionary *)rewriteRuleFromMatchingRules:(NSArray<NSDictionary *> *)matchingRules
{
    for (NSDictionary *matchingRule in matchingRules) {
        if (matchingRule[SBTProxyURLProtocolRewriteResponse] != nil) {
            return matchingRule;
        }
    }
    
    return nil;
}

- (NSDictionary *)stubRuleFromMatchingRules:(NSArray<NSDictionary *> *)matchingRules
{
    for (NSDictionary *matchingRule in matchingRules) {
        if (matchingRule[SBTProxyURLProtocolStubResponse] != nil) {
            return matchingRule;
        }
    }
    
    return nil;
}

- (NSDictionary *)monitorRuleFromMatchingRules:(NSArray<NSDictionary *> *)matchingRules
{
    for (NSDictionary *matchingRule in matchingRules) {
        if (matchingRule[SBTProxyURLProtocolStubResponse] == nil &&
            matchingRule[SBTProxyURLProtocolDelayResponseTimeKey] == nil &&
            matchingRule[SBTProxyURLProtocolRewriteResponse] == nil &&
            matchingRule[SBTProxyURLProtocolDelayResponseTimeKey] == nil &&
            matchingRule[SBTProxyURLProtocolBlockCookiesKey] == nil) {
            return matchingRule;
        }
    }
    
    return nil;
}

- (NSDictionary *)throttleRuleFromMatchingRules:(NSArray<NSDictionary *> *)matchingRules
{
    for (NSDictionary *matchingRule in matchingRules) {
        if (matchingRule[SBTProxyURLProtocolDelayResponseTimeKey] != nil) {
            return matchingRule;
        }
    }
    
    return nil;
}

- (NSDictionary *)blockCookieRuleFromMatchingRules:(NSArray<NSDictionary *> *)matchingRules
{
    for (NSDictionary *matchingRule in matchingRules) {
        if (matchingRule[SBTProxyURLProtocolBlockCookiesKey] != nil) {
            return matchingRule;
        }
    }
    
    return nil;
}

// NSURLProtocol emits a runtime warning when a non-plist type is given to `setProperty`:
//
//    API MISUSE: properties set by +[NSURLProtocol setProperty:forKey:inRequest:] should only include property
//    list types (NSArray, NSDictionary, NSString, NSData, NSDate, NSNumber).
//
// The methods below perform serialization for NSURLRequest types before/after they are sent through NSURLProtocol.

/// Finds the original request in NSURLProtocol and deserializes it
+ (NSURLRequest *)originalRequestFor:(NSURLRequest*)request {
    NSData *serializedOriginal = [SBTRequestPropertyStorage propertyForKey:SBTProxyURLOriginalRequestKey inRequest:request];
    NSURLRequest *originalRequest = nil;

    if (serializedOriginal) {
        // needs to be deserialized after retrieving from NSURLProtocol
        NSError *unarchiveError;
        NSSet *classes = [NSSet setWithObjects:[NSURLRequest class], [NSMutableURLRequest class], nil];
        originalRequest = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:serializedOriginal error:&unarchiveError];
        NSAssert(unarchiveError == nil, @"Error unarchiving NSURLRequest from NSURLProtocol");
    }

    return originalRequest;
}

/// Associates the original request to the current request by serializing and storing it
+ (void)associateOriginalRequest:(NSURLRequest *)original withRequest:(NSMutableURLRequest*)request {
    // serialize the request since only plist values should be given to `setProperty:`
    NSError *archiveError;
    NSData *serializedOriginal = [NSKeyedArchiver archivedDataWithRootObject:original
                                                       requiringSecureCoding:YES
                                                                       error:&archiveError];
    NSAssert(archiveError == nil, @"Error archiving NSURLRequest for NSURLProtocol");

    [SBTRequestPropertyStorage setProperty:serializedOriginal forKey:SBTProxyURLOriginalRequestKey inRequest:request];
}

@end
