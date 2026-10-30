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

#import "include/SBTProxyURLProtocol.h"

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
@property (nonatomic, strong) NSMutableData *connectionData;
@property (nonatomic, strong) NSDate *connectionStartDate;

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *matchingRules;
@property (nonatomic, strong) NSMutableArray<SBTMonitoredNetworkRequest *> *monitoredRequests;
@property (nonatomic, strong) dispatch_queue_t monitoredRequestsSyncQueue;
@property (nonatomic, strong) dispatch_queue_t responseDeliveryQueue;

@property (nonatomic, strong) NSURLResponse *response;
// Only accessed on the proxy session's delegate queue. Set when the proxied response is a redirect
@property (nonatomic, strong) NSURLRequest *redirectRequest;
// The task drops its response when reading the body of the redirect fails
@property (nonatomic, strong) NSHTTPURLResponse *redirectResponse;

// The URL loading system calls startLoading and stopLoading on this thread and expects client callbacks on it, in these run loop modes
@property (nonatomic, strong) NSThread *clientThread;
@property (nonatomic, copy) NSArray<NSString *> *clientRunLoopModes;
// Only accessed on clientThread. Set by stopLoading and by the terminal callbacks: once set, the client must not be called anymore
@property (nonatomic, assign) BOOL finished;

@end

@implementation SBTProxyURLProtocol

+ (BOOL)removeRequestsWithIds:(NSArray<NSString *> *)reqIds matchingRule:(BOOL (^)(NSDictionary *rule))matchesRule
{
    NSSet<NSString *> *requestedIds = [NSSet setWithArray:reqIds];
    NSMutableSet<NSString *> *removedIds = [NSMutableSet set];
    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet indexSet];

    @synchronized (self.sharedInstance) {
        [self.sharedInstance.matchingRules enumerateObjectsUsingBlock:^(NSDictionary *rule, NSUInteger index, BOOL *stop) {
            NSString *identifier = rule[SBTProxyURLProtocolMatchingRuleIdentifierKey];
            if ([requestedIds containsObject:identifier] && matchesRule(rule)) {
                [indexesToRemove addIndex:index];
                [removedIds addObject:identifier];
            }
        }];
        [self.sharedInstance.matchingRules removeObjectsAtIndexes:indexesToRemove];
    }

    return removedIds.count == requestedIds.count;
}

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
    self.monitoredRequests = [NSMutableArray array];
    self.monitoredRequestsSyncQueue = dispatch_queue_create("com.sbtuitesttunnel.protocol.queue", DISPATCH_QUEUE_SERIAL);
    self.responseDeliveryQueue = dispatch_queue_create("com.sbtuitesttunnel.protocol.delivery", DISPATCH_QUEUE_SERIAL);
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
    if (reqId == nil) {
        return NO;
    }
    return [self throttleRequestsRemoveWithIds:@[reqId]];
}

+ (BOOL)throttleRequestsRemoveWithIds:(NSArray<NSString *> *)reqIds
{
    return [self removeRequestsWithIds:reqIds matchingRule:^BOOL(NSDictionary *rule) {
        return rule[SBTProxyURLProtocolDelayResponseTimeKey] != nil;
    }];
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
    if (reqId == nil) {
        return NO;
    }
    return [self monitorRequestsRemoveWithIds:@[reqId]];
}

+ (BOOL)monitorRequestsRemoveWithIds:(NSArray<NSString *> *)reqIds
{
    return [self removeRequestsWithIds:reqIds matchingRule:^BOOL(NSDictionary *rule) {
        return rule[SBTProxyURLProtocolStubResponse] == nil &&
               rule[SBTProxyURLProtocolDelayResponseTimeKey] == nil &&
               rule[SBTProxyURLProtocolRewriteResponse] == nil &&
               rule[SBTProxyURLProtocolBlockCookiesKey] == nil;
    }];
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
    if (reqId == nil) {
        return NO;
    }
    return [self stubRequestsRemoveWithIds:@[reqId]];
}

+ (BOOL)stubRequestsRemoveWithIds:(NSArray<NSString *> *)reqIds
{
    return [self removeRequestsWithIds:reqIds matchingRule:^BOOL(NSDictionary *rule) {
        return rule[SBTProxyURLProtocolStubResponse] != nil;
    }];
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
            if (response != nil) {
                SBTActiveStub *activeStub = [[SBTActiveStub alloc] initWithMatch:match response:response];
                [activeStubs addObject:activeStub];
            }
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
    if (reqId == nil) {
        return NO;
    }
    return [self rewriteRequestsRemoveWithIds:@[reqId]];
}

+ (BOOL)rewriteRequestsRemoveWithIds:(NSArray<NSString *> *)reqIds
{
    return [self removeRequestsWithIds:reqIds matchingRule:^BOOL(NSDictionary *rule) {
        return rule[SBTProxyURLProtocolRewriteResponse] != nil;
    }];
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
    if (reqId == nil) {
        return NO;
    }
    return [self cookieBlockRequestsRemoveWithIds:@[reqId]];
}

+ (BOOL)cookieBlockRequestsRemoveWithIds:(NSArray<NSString *> *)reqIds
{
    return [self removeRequestsWithIds:reqIds matchingRule:^BOOL(NSDictionary *rule) {
        return rule[SBTProxyURLProtocolBlockCookiesKey] != nil;
    }];
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
    self.clientThread = [NSThread currentThread];
    NSMutableArray<NSString *> *clientRunLoopModes = [NSMutableArray arrayWithObject:NSDefaultRunLoopMode];
    NSString *currentRunLoopMode = [NSRunLoop currentRunLoop].currentMode;
    if (currentRunLoopMode != nil && ![currentRunLoopMode isEqualToString:NSDefaultRunLoopMode]) {
        [clientRunLoopModes addObject:currentRunLoopMode];
    }
    self.clientRunLoopModes = clientRunLoopModes;

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
        
        NSURLRequest *request = self.request;
        // Wait on a background queue rather than the main queue: `takeOff`
        // parks the main thread on a semaphore during the startup-command
        // handshake, so a startup command that synchronously waits on a stubbed
        // request would otherwise deadlock. The response is then delivered on
        // the client thread, a CFNetwork thread rather than main.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(stubbingResponseTime * NSEC_PER_SEC)), [SBTProxyURLProtocol sharedInstance].responseDeliveryQueue, ^{
            [self performOnClientThread:^{
                if (self.finished) {
                    return;
                }
            
                self.response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:stubbingStatusCode HTTPVersion:nil headerFields:stubResponse.headers];
            
                if ([self monitorRuleFromMatchingRules:matchingRules] != nil) {
                    SBTMonitoredNetworkRequest *monitoredRequest = [[SBTMonitoredNetworkRequest alloc] init];
                
                    monitoredRequest.timestamp = [[NSDate date] timeIntervalSinceReferenceDate];
                    monitoredRequest.requestTime = stubbingResponseTime;
                    monitoredRequest.request = self.request;
                    monitoredRequest.originalRequest = self.request;
                
                    monitoredRequest.response = (NSHTTPURLResponse *)self.response;
                
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
            
                    [self deliverFailure:error];
                } else {
                    if (stubResponse.headers[@"Location"] != nil) {
                        NSURL *redirectionUrl = [NSURL URLWithString:stubResponse.headers[@"Location"]];
                        NSMutableURLRequest *redirectionRequest = [NSMutableURLRequest requestWithURL:redirectionUrl];
                    
                        [NSURLProtocol removePropertyForKey:SBTProxyURLProtocolHandledKey inRequest:redirectionRequest];
                        if (![SBTRequestPropertyStorage propertyForKey:SBTProxyURLOriginalRequestKey inRequest:redirectionRequest]) {
                            // don't handle double (or more) redirects
                            [[self class] associateOriginalRequest:request withRequest:redirectionRequest];
                        }

                        [self deliverRedirectToRequest:redirectionRequest redirectResponse:self.response];
                    }
                    
                    [self deliverResponse:self.response];
                    [self deliverData:stubResponse.data];
                    [self deliverFinish];
                }
            
                if (stubResponse.activeIterations > 0) {
                    if (--stubResponse.activeIterations == 0) {
                        [SBTProxyURLProtocol stubRequestsRemoveWithId:stubRule[SBTProxyURLProtocolMatchingRuleIdentifierKey]];
                    }
                }
            }];
        });
        
        return;
    }
    
    if (monitorRule != nil || throttleRule != nil || rewriteRule != nil || cookieBlockRule != nil || stubbingHeaders) {
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
        self.connectionStartDate = [NSDate date];
        self.connectionData = [NSMutableData data];

        NSTimeInterval delayResponseTime = [self delayResponseTime];
        __weak typeof(self)weakSelf = self;
        // See the stub delivery above: dispatch off the main queue so a startup
        // command that synchronously waits on a throttled/passed-through request
        // doesn't deadlock while `takeOff` has the main thread parked.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayResponseTime * NSEC_PER_SEC)), [SBTProxyURLProtocol sharedInstance].responseDeliveryQueue, ^{
            [weakSelf.connection resume];
        });
    }
}

- (void)stopLoading
{
    self.finished = YES;
    [self.connection cancel];
}

- (void)performOnClientThread:(dispatch_block_t)block
{
    if ([NSThread currentThread] == self.clientThread) {
        block();
    } else {
        [self performSelector:@selector(sbt_performBlock:) onThread:self.clientThread withObject:[block copy] waitUntilDone:NO modes:self.clientRunLoopModes];
    }
}

- (void)sbt_performBlock:(dispatch_block_t)block
{
    block();
}

#pragma mark - Client delivery

// Every client call goes through these methods. They run on the client thread and check before each call that the
// load hasn't ended, as a client callback can synchronously stop the load.

- (void)deliverResponse:(NSURLResponse *)response
{
    // The URL loading system records the storage policy on the response object: handing the client the proxied
    // task's own response would stop that task from caching it and from revalidating it with ETag/Last-Modified
    NSURLResponse *clientResponse = response;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        clientResponse = [[NSHTTPURLResponse alloc] initWithURL:httpResponse.URL statusCode:httpResponse.statusCode HTTPVersion:nil headerFields:httpResponse.allHeaderFields];
    }

    [self performOnClientThread:^{
        if (!self.finished) {
            [self.client URLProtocol:self didReceiveResponse:clientResponse cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        }
    }];
}

- (void)deliverData:(NSData *)data
{
    [self performOnClientThread:^{
        if (!self.finished) {
            [self.client URLProtocol:self didLoadData:data];
        }
    }];
}

// Doesn't end the load: the URL loading system stops it when it follows the redirect, and when the redirect is declined
// the redirect response and its body complete the load instead. Deliver them in the same client thread turn as the
// redirect: if they arrive after the redirect was followed but before this load is stopped, the URL loading system ends
// the request with them.
- (void)deliverRedirectToRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    [self performOnClientThread:^{
        if (!self.finished) {
            [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
        }
    }];
}

- (void)deliverFinish
{
    [self performOnClientThread:^{
        if (!self.finished) {
            self.finished = YES;
            [self.client URLProtocolDidFinishLoading:self];
        }
    }];
}

- (void)deliverFailure:(NSError *)error
{
    [self performOnClientThread:^{
        if (!self.finished) {
            self.finished = YES;
            [self.client URLProtocol:self didFailWithError:error];
        }
    }];
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
    [self.connectionData appendData:data];

    NSArray<NSDictionary *> *matchingRules = [SBTProxyURLProtocol matchingRulesForRequest:self.request];
    if (self.redirectRequest != nil || [self rewriteRuleFromMatchingRules:matchingRules] != nil) {
        // Redirects and rewritten responses are delivered once everything was received
        return;
    }
    
    [self deliverData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    // The session only runs this task, and retains its delegate until it gets invalidated
    [session finishTasksAndInvalidate];

    NSArray<NSDictionary *> *matchingRules = [SBTProxyURLProtocol matchingRulesForRequest:self.request];
    NSURLRequest *request = self.request;
    NSDictionary *rewriteRule = [self rewriteRuleFromMatchingRules:matchingRules];
    BOOL isRequestRewritten = (rewriteRule != nil);
    
    NSTimeInterval requestTime = -1.0 * [self.connectionStartDate timeIntervalSinceNow];

    NSData *responseData = self.connectionData;

    self.response = task.response ?: self.redirectResponse;

    if (isRequestRewritten) {
        SBTRewrite *rewrite = rewriteRule[SBTProxyURLProtocolRewriteResponse];
        responseData = [rewrite rewriteResponseBody:responseData];
        NSHTTPURLResponse *taskResponse = (NSHTTPURLResponse *)self.response;
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
    
    NSURLResponse *response = self.response;
    NSURLRequest *redirectRequest = self.redirectRequest;

    // Redirects and rewritten responses are withheld until the load completes: when a rewritten load failed, the client
    // only gets the failure. A redirect is still reported when reading its body failed, as following it doesn't need the
    // body: the failure only ends the load when the redirect is declined.
    if (error == nil && response == nil) {
        error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil];
    }
    if (error != nil && redirectRequest == nil) {
        [self deliverFailure:error];
        return;
    }

    BOOL isResponseWithheld = isRequestRewritten || redirectRequest != nil;
    [self performOnClientThread:^{
        if (redirectRequest != nil) {
            [self deliverRedirectToRequest:redirectRequest redirectResponse:response];
        }
        if (isResponseWithheld) {
            [self deliverResponse:response];
            [self deliverData:responseData];
        }
        if (error != nil) {
            [self deliverFailure:error];
        } else {
            [self deliverFinish];
        }
    }];
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
    
    self.redirectRequest = mRequest;
    self.redirectResponse = response;

    // The URL loading system follows the redirect: this task completes with the redirect response instead
    completionHandler(nil);
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    if (self.redirectRequest != nil) {
        // Delivered with the redirect once everything was received
        completionHandler(NSURLSessionResponseAllow);
        return;
    }

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
        
        [self deliverResponse:response];
        if (headersMatch) {
            // The stub replaces the body and finishes the load, so the rest of the real load doesn't reach the client
            [self deliverData:stubResponse.data];
            [self deliverFinish];
        }
    } else {
        [self deliverResponse:response];
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
    NSURLRequest *requestToMatch = [self originalRequestFor:request] ?: request;
    
    @synchronized (self.sharedInstance) {
        for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
            SBTRequestMatch *match = matchingRule[SBTProxyURLProtocolMatchingRuleKey];
            if (match == nil) {
                NSAssert(NO, @"???");
                continue;
            }

            if ([match matchesURLRequest:requestToMatch]) {
                [ret addObject:matchingRule];
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
