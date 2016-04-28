// SBTNetworkRequestsMonitor.m
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

#import "SBTNetworkRequestsMonitor.h"
#import "NSURLRequest+SBTUITestTunnelMatch.h"
#import "NSString+NSHash.h"

static NSString * const SBTNetworkRequestsMonitorHandledKey = @"URLMonitorerHandledKey";
static NSString * const SBTNetworkRequestsMonitorRegexRuleKey = @"SBTNetworkRequestsMonitorRegexRuleKey";
static NSString * const SBTNetworkRequestsMonitorQueryRuleKey = @"SBTNetworkRequestsMonitorQueryRuleKey";
static NSString * const SBTNetworkRequestsMonitorMonitorTimeKey = @"SBTNetworkRequestsMonitorMonitorTimeKey";
static NSString * const SBTNetworkRequestsMonitorBlockKey = @"SBTNetworkRequestsMonitorBlockKey";

@interface SBTNetworkRequestsMonitor() <NSURLSessionDataDelegate,NSURLSessionTaskDelegate,NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *connection;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableData *> *tasksData;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSDate *> *tasksTime;

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *matchingRules;

@property (nonatomic, strong) NSURLResponse *response;

@end

@implementation SBTNetworkRequestsMonitor

+ (SBTNetworkRequestsMonitor *)sharedInstance
{
    static SBTNetworkRequestsMonitor *sharedInstance;
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[SBTNetworkRequestsMonitor alloc] init];
            sharedInstance.matchingRules = [NSMutableArray array];
            sharedInstance.tasksData = [NSMutableDictionary dictionary];
            sharedInstance.tasksTime = [NSMutableDictionary dictionary];
        }
    }
    
    return sharedInstance;
}

+ (NSString *)monitorRequestsWithRegex:(NSString *)regexPattern monitorBlock:(void(^)(NSURLRequest *request, NSURLRequest *originalRequest, NSHTTPURLResponse *response, NSData *responseData, NSTimeInterval requestTime))block;
{
    NSDictionary *rule = @{SBTNetworkRequestsMonitorRegexRuleKey: regexPattern, SBTNetworkRequestsMonitorBlockKey: [block copy]};
    
    [self.sharedInstance.matchingRules addObject:rule];
    
    return [self identifierForRule:rule];
}

+ (NSString *)monitorRequestsWithQueryParams:(NSArray<NSString *> *)queryParams monitorBlock:(void(^)(NSURLRequest *request, NSURLRequest *originalRequest, NSHTTPURLResponse *response, NSData *responseData, NSTimeInterval requestTime))block;
{
    NSDictionary *rule = @{SBTNetworkRequestsMonitorQueryRuleKey: queryParams, SBTNetworkRequestsMonitorBlockKey: [block copy]};
    
    [self.sharedInstance.matchingRules addObject:rule];
    
    return [self identifierForRule:rule];
}

+ (BOOL)monitorRequestsRemoveWithId:(nonnull NSString *)recId
{
    NSMutableArray *itemsToDelete = [NSMutableArray array];
    for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
        if ([[self identifierForRule:matchingRule] isEqualToString:recId]) {
            [itemsToDelete addObject:matchingRule];
            break;
        }
    }
    
    [self.sharedInstance.matchingRules removeObjectsInArray:itemsToDelete];
    
    return NO;
}
         
+ (void)monitorRequestsRemoveAll
{
    self.sharedInstance.matchingRules = [NSMutableArray array];
}

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([NSURLProtocol propertyForKey:SBTNetworkRequestsMonitorHandledKey inRequest:request]) {
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
    [NSURLProtocol setProperty:@YES forKey:SBTNetworkRequestsMonitorHandledKey inRequest:newRequest];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    self.connection = [session dataTaskWithRequest:newRequest];
    
    [SBTNetworkRequestsMonitor sharedInstance].tasksTime[@(self.connection.taskIdentifier)] = [NSDate date];

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
    
    NSMutableData *taskData = [[SBTNetworkRequestsMonitor sharedInstance].tasksData objectForKey:@(dataTask.taskIdentifier)];
    [taskData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (!error) {
        [self.client URLProtocolDidFinishLoading:self];
        
        NSDictionary *matchingRule = [SBTNetworkRequestsMonitor matchingRuleForRequest:self.request];
        
        void(^block)(NSURLRequest *request, NSURLRequest *originalRequest, NSHTTPURLResponse *response, NSData *responseData, NSTimeInterval requestTime) = matchingRule[SBTNetworkRequestsMonitorBlockKey];
        
        if ([self.response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSTimeInterval requestTime = -1.0 * [[SBTNetworkRequestsMonitor sharedInstance].tasksTime[@(task.taskIdentifier)] timeIntervalSinceNow];
            __block typeof(self) weakSelf = self;
            
            NSData *requestData = [SBTNetworkRequestsMonitor sharedInstance].tasksData[@(task.taskIdentifier)];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                block(weakSelf.request, task.originalRequest, (NSHTTPURLResponse *)weakSelf.response, requestData, requestTime);
            });
        }
        
        NSAssert([SBTNetworkRequestsMonitor sharedInstance].tasksData[@(task.taskIdentifier)] != nil, @"Nil task in tasks?");
        [[SBTNetworkRequestsMonitor sharedInstance].tasksData removeObjectForKey:@(task.taskIdentifier)];
    } else {
        [self.client URLProtocol:self didFailWithError:error];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    [[SBTNetworkRequestsMonitor sharedInstance].tasksData setObject:[[NSMutableData alloc] init] forKey:@(dataTask.taskIdentifier)];
    
    self.response = response;
    
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    NSMutableURLRequest *mRequest = [request mutableCopy];
    
    [NSURLProtocol removePropertyForKey:SBTNetworkRequestsMonitorHandledKey inRequest:mRequest];
    
    [self.client URLProtocol:self wasRedirectedToRequest:mRequest redirectResponse:response];
    
    completionHandler(mRequest);
}

#pragma mark - Helper Methods

+ (NSDictionary *)matchingRuleForRequest:(NSURLRequest *)request
{
    for (NSDictionary *matchingRule in self.sharedInstance.matchingRules) {
        if ([matchingRule.allKeys containsObject:SBTNetworkRequestsMonitorRegexRuleKey]) {
            if ([request matchesRegexPattern:matchingRule[SBTNetworkRequestsMonitorRegexRuleKey]]) {
                return matchingRule;
            }
        } else if ([matchingRule.allKeys containsObject:SBTNetworkRequestsMonitorQueryRuleKey]) {
            if ([request matchesQueryParams:matchingRule[SBTNetworkRequestsMonitorQueryRuleKey]]) {
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
    if ([rule.allKeys containsObject:SBTNetworkRequestsMonitorRegexRuleKey]) {
        identifier = [rule[SBTNetworkRequestsMonitorRegexRuleKey] SHA1];
    } else if ([rule.allKeys containsObject:SBTNetworkRequestsMonitorQueryRuleKey]) {
        NSError *error = nil;
        NSData *ruleData = [NSJSONSerialization dataWithJSONObject:rule[SBTNetworkRequestsMonitorQueryRuleKey] options:NSJSONWritingPrettyPrinted error:&error];
        NSAssert(error == nil || !ruleData, @"???");
        
        identifier = [[[NSString alloc] initWithData:ruleData encoding:NSUTF8StringEncoding] SHA1];
    } else {
        NSAssert(NO, @"???");
    }

    return [@"rec-" stringByAppendingString:identifier];
}

@end
