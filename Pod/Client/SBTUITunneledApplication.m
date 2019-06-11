// SBTUITestTunnelClient.m
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

    #ifndef ENABLE_UITUNNEL_SWIZZLING
        #define ENABLE_UITUNNEL_SWIZZLING 1
    #endif
#endif

#if ENABLE_UITUNNEL

#import "SBTUITunneledApplication.h"
#import "SBTUITestTunnelClient.h"
#import "XCTestCase+Swizzles.h"

@interface SBTUITunneledApplication () <SBTUITestTunnelClientDelegate>
@property (nonatomic, strong) SBTUITestTunnelClient *client;
@end

@implementation SBTUITunneledApplication

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _client = [[SBTUITestTunnelClient alloc] initWithApplication:self];
        _client.delegate = self;
    }
    return self;
}

+ (void)load
{
#if ENABLE_UITUNNEL_SWIZZLING
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [XCTestCase loadSwizzles];
    });
#endif
}

- (void)launchTunnelWithOptions:(nonnull NSArray<NSString *> *)options startupBlock:(nullable void (^)(void))startupBlock
{
    NSMutableArray *launchArguments = [self.launchArguments mutableCopy];
    [launchArguments addObjectsFromArray:options];

    self.launchArguments = launchArguments;

    [self launchTunnelWithStartupBlock: startupBlock];
}

# pragma mark - SBTUITestTunnelClientDelegate

- (void)testTunnelClientIsReadyToLaunch:(nonnull SBTUITestTunnelClient *)sender
{
    [self launch];
}

- (void)testTunnelClient:(nonnull SBTUITestTunnelClient *)sender didShutdownWithError:(NSError * _Nullable)error
{
    if (error != nil) {
        NSAssert(NO, error.localizedDescription);
    }
    [self terminate];
}

# pragma mark - SBTUITestTunnelClientProtocol -

- (void)launchTunnel
{
    [self.client launchTunnel];
}

- (void)launchTunnelWithStartupBlock:(nullable void (^)(void))startupBlock
{
    [self.client launchTunnelWithStartupBlock:startupBlock];
}

- (void)launchConnectionless:(nonnull NSString * _Nonnull (^)(NSString * _Nonnull, NSDictionary<NSString *,NSString *> * _Nonnull))command
{
    [self.client launchConnectionless:command];
}

#pragma mark - Timeout

+ (void)setConnectionTimeout:(NSTimeInterval)timeout
{
    [SBTUITestTunnelClient setConnectionTimeout:timeout];
}

#pragma mark - Quit Command

- (void)quit
{
    [self.client quit];
}

#pragma mark - Stub Commands

- (nullable NSString *)stubRequestsMatching:(nonnull SBTRequestMatch *)match response:(nonnull SBTStubResponse *)response
{
    return [self.client  stubRequestsMatching:match response:response];
}

#pragma mark - Stub And Remove Commands

- (nullable NSString *)stubRequestsMatching:(nonnull SBTRequestMatch *)match response:(nonnull SBTStubResponse *)response removeAfterIterations:(NSUInteger)iterations
{
    return [self.client stubRequestsMatching:match response:response removeAfterIterations:iterations];
}

#pragma mark - Stub Remove Commands

- (BOOL)stubRequestsRemoveWithId:(nonnull NSString *)stubId
{
    return [self.client stubRequestsRemoveWithId:stubId];
}

- (BOOL)stubRequestsRemoveWithIds:(nonnull NSArray<NSString *> *)stubIds
{
    return [self.client stubRequestsRemoveWithIds:stubIds];
}

- (BOOL)stubRequestsRemoveAll
{
    return [self.client stubRequestsRemoveAll];
}

#pragma mark - Rewrite Commands

- (nullable NSString *)rewriteRequestsMatching:(nonnull SBTRequestMatch *)match rewrite:(nonnull SBTRewrite *)rewrite
{
    return [self.client rewriteRequestsMatching:match rewrite:rewrite];
}

#pragma mark - Rewrite And Remove Commands

- (nullable NSString *)rewriteRequestsMatching:(nonnull SBTRequestMatch *)match rewrite:(nonnull SBTRewrite *)rewrite removeAfterIterations:(NSUInteger)iterations
{
    return [self.client rewriteRequestsMatching:match rewrite:rewrite removeAfterIterations:iterations];
}

#pragma mark - Rewrite Remove Commands

- (BOOL)rewriteRequestsRemoveWithId:(nonnull NSString *)rewriteId
{
    return [self.client rewriteRequestsRemoveWithId:rewriteId];
}

- (BOOL)rewriteRequestsRemoveWithIds:(nonnull NSArray<NSString *> *)rewriteIds
{
    return [self.client rewriteRequestsRemoveWithIds:rewriteIds];
}

- (BOOL)rewriteRequestsRemoveAll
{
    return [self.client rewriteRequestsRemoveAll];
}

#pragma mark - Monitor Requests Commands

- (nullable NSString *)monitorRequestsMatching:(nonnull SBTRequestMatch *)match
{
    return [self.client monitorRequestsMatching:match];
}

- (nonnull NSArray<SBTMonitoredNetworkRequest *> *)monitoredRequestsPeekAll
{
    return [self.client monitoredRequestsPeekAll];
}

- (nonnull NSArray<SBTMonitoredNetworkRequest *> *)monitoredRequestsFlushAll
{
    return [self.client monitoredRequestsFlushAll];
}

- (BOOL)monitorRequestRemoveWithId:(nonnull NSString *)reqId
{
    return [self.client monitorRequestRemoveWithId:reqId];
}

- (BOOL)monitorRequestRemoveWithIds:(nonnull NSArray<NSString *> *)reqIds
{
    return [self.client monitorRequestRemoveWithIds:reqIds];
}

- (BOOL)monitorRequestRemoveAll
{
    return [self.client monitorRequestRemoveAll];
}

#pragma mark - Synchronously Wait for Requests Commands

- (BOOL)waitForMonitoredRequestsMatching:(nonnull SBTRequestMatch *)match timeout:(NSTimeInterval)timeout
{
    return [self.client waitForMonitoredRequestsMatching:match timeout:timeout];
}

- (BOOL)waitForMonitoredRequestsMatching:(nonnull SBTRequestMatch *)match timeout:(NSTimeInterval)timeout iterations:(NSUInteger)iterations
{
    return [self.client waitForMonitoredRequestsMatching:match timeout:timeout iterations:iterations];
}

#pragma mark - Throttle Requests Commands

- (nullable NSString *)throttleRequestsMatching:(nonnull SBTRequestMatch *)match responseTime:(NSTimeInterval)responseTime
{
    return [self.client  throttleRequestsMatching:match responseTime:responseTime];
}

- (BOOL)throttleRequestRemoveWithId:(nonnull NSString *)reqId
{
    return [self.client throttleRequestRemoveWithId:reqId];
}

- (BOOL)throttleRequestRemoveWithIds:(nonnull NSArray<NSString *> *)reqIds
{
    return [self.client throttleRequestRemoveWithIds:reqIds];
}

- (BOOL)throttleRequestRemoveAll
{
    return [self.client throttleRequestRemoveAll];
}

#pragma mark - Cookie Block Requests Commands

- (nullable NSString *)blockCookiesInRequestsMatching:(nonnull SBTRequestMatch *)match
{
    return [self.client blockCookiesInRequestsMatching:match];
}

- (nullable NSString *)blockCookiesInRequestsMatching:(nonnull SBTRequestMatch *)match iterations:(NSUInteger)iterations
{
    return [self.client blockCookiesInRequestsMatching:match iterations:iterations];
}

- (BOOL)blockCookiesRequestsRemoveWithId:(nonnull NSString *)reqId
{
    return [self.client blockCookiesRequestsRemoveWithId:reqId];
}

- (BOOL)blockCookiesRequestsRemoveWithIds:(nonnull NSArray<NSString *> *)reqIds
{
    return [self.client blockCookiesRequestsRemoveWithIds:reqIds];
}

- (BOOL)blockCookiesRequestsRemoveAll
{
    return [self.client blockCookiesRequestsRemoveAll];
}

#pragma mark - NSUserDefaults Commands

- (BOOL)userDefaultsSetObject:(nonnull id<NSCoding>)object forKey:(nonnull NSString *)key
{
    return [self.client userDefaultsSetObject:object forKey:key];
}

- (BOOL)userDefaultsRemoveObjectForKey:(nonnull NSString *)key
{
    return [self.client userDefaultsRemoveObjectForKey:key];
}

- (nullable id)userDefaultsObjectForKey:(nonnull NSString *)key
{
    return [self.client userDefaultsObjectForKey:key];
}

- (BOOL)userDefaultsReset
{
    return [self.client userDefaultsReset];
}

- (BOOL)userDefaultsSetObject:(nonnull id<NSCoding>)object forKey:(nonnull NSString *)key suiteName:(nonnull NSString *)suiteName
{
    return [self.client  userDefaultsSetObject:object forKey:key suiteName:suiteName];
}

- (BOOL)userDefaultsRemoveObjectForKey:(nonnull NSString *)key suiteName:(nonnull NSString *)suiteName
{
    return [self.client userDefaultsRemoveObjectForKey:key suiteName:suiteName];
}

- (nullable id)userDefaultsObjectForKey:(nonnull NSString *)key suiteName:(nonnull NSString *)suiteName
{
    return [self.client userDefaultsObjectForKey:key suiteName:suiteName];
}

- (BOOL)userDefaultsResetSuiteName:(nonnull NSString *)suiteName
{
    return [self.client userDefaultsResetSuiteName:suiteName];
}

#pragma mark - NSBundle

- (nullable NSDictionary<NSString *,id> *)mainBundleInfoDictionary
{
    return [self.client mainBundleInfoDictionary];
}

#pragma mark - Copy Commands

- (BOOL)uploadItemAtPath:(nonnull NSString *)srcPath toPath:(nullable NSString *)destPath relativeTo:(NSSearchPathDirectory)baseFolder
{
    return [self.client uploadItemAtPath:srcPath toPath:destPath relativeTo:baseFolder];
}

- (nullable NSArray<NSData *> *)downloadItemsFromPath:(nonnull NSString *)path relativeTo:(NSSearchPathDirectory)baseFolder
{
    return [self.client downloadItemsFromPath:path relativeTo:baseFolder];
}

#pragma mark - Custom Commands

- (nullable id)performCustomCommandNamed:(nonnull NSString *)commandName object:(nullable id)object
{
    return [self.client performCustomCommandNamed:commandName object:object];
}

#pragma mark - Other Commands

- (BOOL)setUserInterfaceAnimationsEnabled:(BOOL)enabled
{
    return [self.client setUserInterfaceAnimationsEnabled:enabled];
}

- (BOOL)userInterfaceAnimationsEnabled
{
    return [self.client userInterfaceAnimationsEnabled];
}

- (BOOL)setUserInterfaceAnimationSpeed:(NSInteger)speed
{
    return [self.client setUserInterfaceAnimationSpeed:speed];
}

- (NSInteger)userInterfaceAnimationSpeed
{
    return [self.client userInterfaceAnimationSpeed];
}

@end

#endif
