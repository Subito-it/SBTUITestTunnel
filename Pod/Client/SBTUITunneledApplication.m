// SBTUITunneledApplication.m
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

#import "SBTUITunneledApplication.h"
#import "SBTUITestTunnel.h"
#import "NSURLRequest+SBTUITestTunnelMatch.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

const NSString *SBTUITunnelJsonMimeType = @"application/json";

@interface SBTUITunneledApplication() <NSNetServiceDelegate>

@property (nonatomic, assign) NSInteger connectionPort;
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, assign) NSTimeInterval connectionTimeout;
@property (nonatomic, strong) NSMutableArray *stubOnceIds;
@property (nonatomic, strong) NSString *bonjourName;
@property (nonatomic, strong) NSNetService *bonjourBrowser;
@property (nonatomic, strong) void (^startupBlock)(void);
@property (nonatomic, copy) NSArray <NSString *> *initialLaunchArguments;
@property (nonatomic, copy) NSDictionary <NSString *, NSString *> *initialLaunchEnvironment;
@property (nonatomic, strong) NSString *(^connectionlessBlock)(NSString *, NSDictionary<NSString *, NSString *> *);

@end

@implementation SBTUITunneledApplication

static NSTimeInterval SBTUITunneledApplicationDefaultTimeout = 30.0;

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _initialLaunchArguments = self.launchArguments;
        _initialLaunchEnvironment = self.launchEnvironment;
        
        [self resetInternalState];
    }
    
    return self;
}

- (void)resetInternalState
{
    [self.bonjourBrowser stop];

    self.launchArguments = self.initialLaunchArguments;
    self.launchEnvironment = self.initialLaunchEnvironment;

    self.bonjourName = [NSString stringWithFormat:@"com.subito.test.%d.%.0f", [NSProcessInfo processInfo].processIdentifier, (double)(CFAbsoluteTimeGetCurrent() * 100000)];
    self.bonjourBrowser = [[NSNetService alloc] initWithDomain:@"local." type:@"_http._tcp." name:self.bonjourName];
    self.bonjourBrowser.delegate = self;
    self.connected = NO;
    self.connectionPort = 0;
    self.connectionTimeout = SBTUITunneledApplicationDefaultTimeout;
}

- (void)terminate
{
    [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandShutDown params:nil assertOnError:NO];
    
    [self resetInternalState];
    
    [super terminate];
}

- (void)launchTunnel
{
    [self launchTunnelWithOptions:@[] startupBlock:nil];
}

- (void)launchTunnelWithStartupBlock:(void (^)(void))startupBlock;
{
    [self launchTunnelWithOptions:@[] startupBlock:startupBlock];
}

- (void)launchTunnelWithOptions:(NSArray<NSString *> *)options startupBlock:(void (^)(void))startupBlock
{
    NSMutableArray *launchArguments = [self.launchArguments mutableCopy];
    [launchArguments addObjectsFromArray:options];
    
    [launchArguments addObject:SBTUITunneledApplicationLaunchSignal];
    
    if (startupBlock) {
        [launchArguments addObject:SBTUITunneledApplicationLaunchOptionHasStartupCommands];
        self.startupBlock = startupBlock;
    }
    
    self.launchArguments = launchArguments;
    
    NSMutableDictionary<NSString *, NSString *> *launchEnvironment = [self.launchEnvironment mutableCopy];
    launchEnvironment[SBTUITunneledApplicationLaunchEnvironmentBonjourNameKey] = self.bonjourName;
    self.launchEnvironment = launchEnvironment;
    
    NSLog(@"[SBTUITestTunnel] Resolving bonjour service %@", self.bonjourName);
    [self.bonjourBrowser resolveWithTimeout:self.connectionTimeout];
    
    [self launch];
    
    [self waitForAppReady];
}

- (void)launchConnectionless:(NSString * (^)(NSString *, NSDictionary<NSString *, NSString *> *))command
{
    self.connectionlessBlock = command;
}

- (void)waitForAppReady
{
    const int timeout = self.connectionTimeout;
    int i = 0;
    for (i = 0; i < timeout; i++) {
        if ([self isAppCruising]) {
            return;
        }
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    NSAssert(NO, @"[SBTUITestTunnel] Failed waiting app to be ready");
    [self terminate];
}

#pragma mark - Bonjour

- (void)netServiceDidResolveAddress:(NSNetService *)service;
{
    if ([service.name isEqualToString:self.bonjourName] && !self.connected) {
        NSAssert(service.port > 0, @"[SBTUITestTunnel] unexpected port 0!");
        
        self.connected = YES;
        
        NSLog(@"[SBTUITestTunnel] Tunnel established on port %ld", (unsigned long)service.port);
        self.connectionPort = service.port;
        
        if (self.startupBlock) {
            self.startupBlock(); // this will eventually add some commands in the startup command queue
        }
        
        [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStartupCommandsCompleted params:@{}];
    }
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *,NSNumber *> *)errorDict
{
    if (!self.connected || ![sender.name isEqualToString:self.bonjourName]) {
        return;
    }
    
    NSAssert(NO, @"[SBTUITestTunnel] Failed to connect to client app %@", errorDict);
    [self terminate];
}

#pragma mark - Timeout

+ (void)setConnectionTimeout:(NSTimeInterval)timeout
{
    NSAssert(timeout > 5.0, @"[SBTUITestTunnel] Timeout too short!");
    SBTUITunneledApplicationDefaultTimeout = timeout;
}

#pragma mark - Ping Command

- (BOOL)ping
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandPing params:nil assertOnError:NO] isEqualToString:@"YES"];
}

#pragma mark - Quit Command

- (void)quit
{
    [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandQuit params:nil assertOnError:NO];
}

#pragma mark - Ready Command

- (BOOL)isAppCruising
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCruising params:nil] isEqualToString:@"YES"];
}

#pragma mark - Stub Commands

- (NSString *)stubRequestsMatching:(SBTRequestMatch *)match response:(SBTStubResponse *)response
{
    return [self stubRequestsMatching:match response:response removeAfterIterations:0];
}

#pragma mark - Stub And Remove Commands

- (NSString *)stubRequestsMatching:(SBTRequestMatch *)match response:(SBTStubResponse *)response removeAfterIterations:(NSUInteger)iterations
{
    NSData *jsonHeaderData = [NSJSONSerialization dataWithJSONObject:response.headers options:0 error:NULL];
    NSString *headersSerialized = [[NSString alloc] initWithData:jsonHeaderData encoding:NSUTF8StringEncoding];
    
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelStubRuleKey: [self base64SerializeObject:match],
                                                     SBTUITunnelStubReturnDataKey: [self base64SerializeObject:response.data],
                                                     SBTUITunnelStubReturnCodeKey: [@(response.returnCode) stringValue],
                                                     SBTUITunnelStubMimeTypeKey: response.contentType,
                                                     SBTUITunnelStubReturnHeadersKey: headersSerialized,
                                                     SBTUITunnelStubResponseTimeKey: [@(response.responseTime) stringValue],
                                                     SBTUITunnelStubIterationsKey: [@(iterations) stringValue],
                                                     SBTUITunnelStubFailWithCustomErrorKey: [@(response.failureCode) stringValue]
                                                     };
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStubAndRemoveMatching params:params];
}

#pragma mark - Stub Remove Commands

- (BOOL)stubRequestsRemoveWithId:(NSString *)stubId
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelStubRuleKey:[self base64SerializeObject:stubId]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStubRequestsRemove params:params] boolValue];
}

- (BOOL)stubRequestsRemoveWithIds:(NSArray<NSString *> *)stubIds
{
    BOOL ret = YES;
    for (NSString *stubId in stubIds) {
        ret &= [self stubRequestsRemoveWithId:stubId];
    }
    
    return ret;
}

- (BOOL)stubRequestsRemoveAll
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStubRequestsRemoveAll params:nil] boolValue];
}

#pragma mark - Rewrite Commands

- (NSString *)rewriteRequestsMatching:(SBTRequestMatch *)match response:(SBTRewriteResponse *)response
{
    return [self rewriteRequestsMatching:match response:response removeAfterIterations:0];
}

#pragma mark - Rewrite And Remove Commands

- (NSString *)rewriteRequestsMatching:(SBTRequestMatch *)match response:(SBTRewriteResponse *)response removeAfterIterations:(NSUInteger)iterations
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelRewriteMatchRuleKey: [self base64SerializeObject:match],
                                                     SBTUITunnelRewriteRewriteRuleKey: [self base64SerializeObject:response],
                                                     SBTUITunnelRewriteIterationsKey: [@(iterations) stringValue]
                                                     };
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandRewriteAndRemoveMatching params:params];
}

#pragma mark - Rewrite Remove Commands

- (BOOL)rewriteRequestsRemoveWithId:(NSString *)rewriteId
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelRewriteRuleIdKey:[self base64SerializeObject:rewriteId]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandRewriteRequestsRemove params:params] boolValue];
}

- (BOOL)rewriteRequestsRemoveWithIds:(NSArray<NSString *> *)rewriteIds
{
    BOOL ret = YES;
    for (NSString *rewriteId in rewriteIds) {
        ret &= [self rewriteRequestsRemoveWithId:rewriteId];
    }
    
    return ret;
}

- (BOOL)rewriteRequestsRemoveAll
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandRewriteRequestsRemoveAll params:nil] boolValue];
}

#pragma mark - Monitor Requests Commands

- (NSString *)monitorRequestsMatching:(SBTRequestMatch *)match
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelProxyQueryRuleKey: [self base64SerializeObject:match]};
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandMonitorMatching params:params];
}

- (NSArray<SBTMonitoredNetworkRequest *> *)monitoredRequestsPeekAll;
{
    NSString *objectBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandMonitorPeek params:nil];
    if (objectBase64) {
        NSData *objectData = [[NSData alloc] initWithBase64EncodedString:objectBase64 options:0];
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:objectData] ?: @[];
    }
    
    return nil;
}

- (NSArray<SBTMonitoredNetworkRequest *> *)monitoredRequestsFlushAll;
{
    NSString *objectBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandMonitorFlush params:nil];
    if (objectBase64) {
        NSData *objectData = [[NSData alloc] initWithBase64EncodedString:objectBase64 options:0];
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:objectData] ?: @[];
    }
    
    return nil;
}

- (BOOL)monitorRequestRemoveWithId:(NSString *)reqId
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelProxyQueryRuleKey:[self base64SerializeObject:reqId]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandMonitorRemove params:params] boolValue];
}

- (BOOL)monitorRequestRemoveWithIds:(NSArray<NSString *> *)reqIds
{
    BOOL ret = YES;
    for (NSString *reqId in reqIds) {
        ret &= [self monitorRequestRemoveWithId:reqId];
    }
    
    return ret;
}

- (BOOL)monitorRequestRemoveAll
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandMonitorRemoveAll params:nil] boolValue];
}

#pragma mark - Asynchronously Wait for Requests Commands

- (void)waitForMonitoredRequestsMatching:(SBTRequestMatch *)match timeout:(NSTimeInterval)timeout completionBlock:(void (^)(BOOL timeout))completionBlock;
{
    [self waitForMonitoredRequestsMatching:match timeout:timeout iterations:1 completionBlock:completionBlock];
}

- (void)waitForMonitoredRequestsMatching:(SBTRequestMatch *)match timeout:(NSTimeInterval)timeout iterations:(NSUInteger)iterations completionBlock:(void (^)(BOOL timeout))completionBlock;
{
    [self waitForMonitoredRequestsWithMatchingBlock:^BOOL(SBTMonitoredNetworkRequest *request) {
        return [request matches:match];
    } timeout:timeout iterations:iterations completionBlock:completionBlock];
}

- (void)waitForMonitoredRequestsWithMatchingBlock:(BOOL(^)(SBTMonitoredNetworkRequest *))matchingBlock timeout:(NSTimeInterval)timeout iterations:(NSUInteger)iterations completionBlock:(void (^)(BOOL))completionBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
        NSTimeInterval start = CFAbsoluteTimeGetCurrent();
        
        BOOL timedout = NO;
        
        for(;;) {
            NSUInteger localIterations = iterations;
            NSArray<SBTMonitoredNetworkRequest *> *requests = [self monitoredRequestsPeekAll];
            
            for (SBTMonitoredNetworkRequest *request in requests) {
                if (matchingBlock(request)) {
                    if (--localIterations == 0) {
                        break;
                    }
                }
            }
            
            if (localIterations < 1) {
                break;
            } else if (CFAbsoluteTimeGetCurrent() - start > timeout) {
                timedout = YES;
                break;
            }
            
            [NSThread sleepForTimeInterval:0.5];
        }
        
        if (completionBlock) {
            completionBlock(timedout);
        }
    });
}

#pragma mark - Synchronously Wait for Requests Commands

- (BOOL)waitForMonitoredRequestsMatching:(SBTRequestMatch *)match timeout:(NSTimeInterval)timeout;
{
    return [self waitForMonitoredRequestsMatching:match timeout:timeout iterations:1];
}

- (BOOL)waitForMonitoredRequestsMatching:(SBTRequestMatch *)match timeout:(NSTimeInterval)timeout iterations:(NSUInteger)iterations;
{
    __block BOOL result = NO;
    __block BOOL done = NO;
    
    NSLock *doneLock = [[NSLock alloc] init];
    
    [self waitForMonitoredRequestsMatching:match timeout:timeout iterations:iterations completionBlock:^(BOOL didTimeout) {
        result = !didTimeout;
        
        [doneLock lock];
        done = YES;
        [doneLock unlock];
    }];
    
    for (;;) {
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        
        [doneLock lock];
        if (done) {
            [doneLock unlock];
            break;
        }
        [doneLock unlock];
    }
    
    return result;
}

#pragma mark - Throttle Requests Commands

- (NSString *)throttleRequestsMatching:(SBTRequestMatch *)match responseTime:(NSTimeInterval)responseTime;
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelProxyQueryRuleKey: [self base64SerializeObject:match], SBTUITunnelProxyQueryResponseTimeKey: [@(responseTime) stringValue]};
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandThrottleMatching params:params];
}

- (BOOL)throttleRequestRemoveWithId:(NSString *)reqId;
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelProxyQueryRuleKey:[self base64SerializeObject:reqId]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandThrottleRemove params:params] boolValue];
}

- (BOOL)throttleRequestRemoveWithIds:(NSArray<NSString *> *)reqIds;
{
    BOOL ret = YES;
    for (NSString *reqId in reqIds) {
        ret &= [self throttleRequestRemoveWithId:reqId];
    }
    
    return ret;
}

- (BOOL)throttleRequestRemoveAll
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandThrottleRemoveAll params:nil] boolValue];
}

#pragma mark - Cookie Block Requests Commands

- (NSString *)blockCookiesInRequestsMatching:(SBTRequestMatch *)match
{
    return [self blockCookiesInRequestsMatching:match iterations:0];
}

- (NSString *)blockCookiesInRequestsMatching:(SBTRequestMatch *)match iterations:(NSUInteger)iterations
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelCookieBlockQueryRuleKey: [self base64SerializeObject:match],
                                                     SBTUITunnelCookieBlockQueryIterationsKey: [@(iterations) stringValue]};
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCookieBlockAndRemoveMatching params:params];
}

- (BOOL)blockCookiesRequestsRemoveWithId:(NSString *)reqId
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelCookieBlockQueryRuleKey:[self base64SerializeObject:reqId]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCookieBlockRemove params:params] boolValue];
}

- (BOOL)blockCookiesRequestsRemoveWithIds:(NSArray<NSString *> *)reqIds
{
    BOOL ret = YES;
    for (NSString *reqId in reqIds) {
        ret &= [self blockCookiesRequestsRemoveWithId:reqId];
    }
    
    return ret;
}

- (BOOL)blockCookiesRequestsRemoveAll
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCookieBlockRemoveAll params:nil] boolValue];
}

#pragma mark - NSUserDefaults Commands

- (BOOL)userDefaultsSetObject:(id)object forKey:(NSString *)key
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKeyKey: key,
                                                     SBTUITunnelObjectKey: [self base64SerializeObject:object]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandNSUserDefaultsSetObject params:params] boolValue];
}

- (BOOL)userDefaultsRemoveObjectForKey:(NSString *)key
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKeyKey: key};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandNSUserDefaultsRemoveObject params:params] boolValue];
}

- (id)userDefaultsObjectForKey:(NSString *)key
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKeyKey: key};
    
    NSString *objectBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandNSUserDefaultsObject params:params];
    
    if (objectBase64) {
        NSData *objectData = [[NSData alloc] initWithBase64EncodedString:objectBase64 options:0];
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
    }
    
    return nil;
}

- (BOOL)userDefaultsReset
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandNSUserDefaultsReset params:nil] boolValue];
}

#pragma mark - NSBundle

- (nullable NSDictionary<NSString *, id> *)mainBundleInfoDictionary;
{
    NSString *objectBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandMainBundleInfoDictionary params:nil];
    
    if (objectBase64) {
        NSData *objectData = [[NSData alloc] initWithBase64EncodedString:objectBase64 options:0];
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
    }
    
    return nil;
}

#pragma mark - Copy Commands

- (BOOL)uploadItemAtPath:(NSString *)srcPath toPath:(NSString *)destPath relativeTo:(NSSearchPathDirectory)baseFolder
{
    NSAssert(![srcPath hasPrefix:@"file:"], @"Call this methon passing srcPath using [NSURL path] not [NSURL absoluteString]!");
    
    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:srcPath]];
    
    if (!data) {
        return NO;
    }
    
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelUploadDataKey: [self base64SerializeData:data],
                                                     SBTUITunnelUploadDestPathKey: [self base64SerializeObject:destPath ?: @""],
                                                     SBTUITunnelUploadBasePathKey: [@(baseFolder) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandUploadData params:params] boolValue];
}

- (NSArray<NSData *> *)downloadItemsFromPath:(NSString *)path relativeTo:(NSSearchPathDirectory)baseFolder
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelDownloadPathKey: [self base64SerializeObject:path ?: @""],
                                                     SBTUITunnelDownloadBasePathKey: [@(baseFolder) stringValue]};
    
    NSString *itemsBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandDownloadData params:params];
    
    if (itemsBase64) {
        NSData *itemsData = [[NSData alloc] initWithBase64EncodedString:itemsBase64 options:0];
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:itemsData];
    }
    
    return nil;
}

#pragma mark - Custom Commands

- (id)performCustomCommandNamed:(NSString *)commandName object:(id)object
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelCustomCommandKey: commandName,
                                                     SBTUITunnelObjectKey: [self base64SerializeObject:object]};
    
    NSString *objectBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCustom params:params];
    
    if (objectBase64) {
        NSData *objectData = [[NSData alloc] initWithBase64EncodedString:objectBase64 options:0];
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
    }
    
    return nil;
}

#pragma mark - Other Commands

- (BOOL)setUserInterfaceAnimationsEnabled:(BOOL)enabled
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: [@(enabled) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandSetUserInterfaceAnimations params:params] boolValue];
}

- (BOOL)setUserInterfaceAnimationSpeed:(NSInteger)speed
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: [@(speed) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandSetUserInterfaceAnimationSpeed params:params] boolValue];
}

#pragma mark - Helper Methods

- (NSString *)base64SerializeObject:(id)obj
{
    NSData *objData = [NSKeyedArchiver archivedDataWithRootObject:obj];
    
    return [self base64SerializeData:objData];
}

- (NSString *)base64SerializeData:(NSData *)data
{
    if (!data) {
        NSAssert(NO, @"[SBTUITestTunnel] Failed to serialize object");
        [self terminate];
        return @"";
    } else {
        return [[data base64EncodedStringWithOptions:0] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    }
}

- (NSString *)sendSynchronousRequestWithPath:(NSString *)path params:(NSDictionary<NSString *, NSString *> *)params assertOnError:(BOOL)assertOnError
{
    if (self.connectionlessBlock) {
        return self.connectionlessBlock(path, params);
    }
    
    if (self.connectionPort == 0) {
        return nil; // connection still not established
    }
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%d/%@", SBTUITunneledApplicationDefaultHost, (unsigned int)self.connectionPort, path];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = nil;
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    
    NSMutableArray *queryItems = [NSMutableArray array];
    [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
    }];
    components.queryItems = queryItems;
    
    if ([SBTUITunnelHTTPMethod isEqualToString:@"GET"]) {
        request = [NSMutableURLRequest requestWithURL:components.URL];
    } else if  ([SBTUITunnelHTTPMethod isEqualToString:@"POST"]) {
        request = [NSMutableURLRequest requestWithURL:url];
        
        request.HTTPBody = [components.query dataUsingEncoding:NSUTF8StringEncoding];
    }
    request.HTTPMethod = SBTUITunnelHTTPMethod;
    
    if (!request) {
        NSAssert(NO, @"[SBTUITestTunnel] Did fail to create url component");
        [self terminate];
        return nil;
    }
    
    dispatch_semaphore_t synchRequestSemaphore = dispatch_semaphore_create(0);
    
    NSURLSession *session = [NSURLSession sharedSession];
    __block NSString *responseId = nil;
    
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
            if (assertOnError) {
                NSLog(@"[SBTUITestTunnel] Failed to get http response: %@", request);
                // [weakSelf terminate];
            }
        } else {
            NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            responseId = jsonData[SBTUITunnelResponseResultKey];
            
            if (assertOnError) {
                if (((NSHTTPURLResponse *)response).statusCode != 200) {
                    NSLog(@"[SBTUITestTunnel] Message sending failed: %@", request);
                }
            }
        }
        
        dispatch_semaphore_signal(synchRequestSemaphore);
    }] resume];
    
    dispatch_semaphore_wait(synchRequestSemaphore, DISPATCH_TIME_FOREVER);
    
    return responseId;
}

- (NSString *)sendSynchronousRequestWithPath:(NSString *)path params:(NSDictionary<NSString *, NSString *> *)params
{
    return [self sendSynchronousRequestWithPath:path params:params assertOnError:YES];
}

@end

#endif
