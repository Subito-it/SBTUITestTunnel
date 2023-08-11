// SBTUITunneledApplication.m
//
// Copyright (C) 2019 Subito.it S.r.l (www.subito.it)
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

#import "include/SBTUITunneledApplication.h"
#import "include/SBTUITestTunnelClient.h"

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

- (void)launchTunnelWithOptions:(NSArray<NSString *> *)options startupBlock:(void (^)(void))startupBlock
{
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunguarded-availability-new"
    [self openTunnelWithURL:nil options:options startupBlock:startupBlock];
#pragma GCC diagnostic pop
}

- (void)launchTunnelWithOptions:(NSArray<NSString *> *)options url:(NSURL *)url startupBlock:(void (^)(void))startupBlock
{
    NSMutableArray *launchArguments = [self.launchArguments mutableCopy];
    [launchArguments addObjectsFromArray:options];

    self.launchArguments = launchArguments;

    [self openTunnelWithURL:url startupBlock:startupBlock];
}

# pragma mark - SBTUITestTunnelClientDelegate

- (void)tunnelClientIsReadyToLaunch:(SBTUITestTunnelClient *)sender url:(NSURL *)url
{
    if (@available(iOS 16.4, *)) {
        if (url) {
            [self openURL:url];
            return;
        }
    }
    [self launch];
}

- (void)tunnelClient:(SBTUITestTunnelClient *)sender didShutdownWithError:(NSError *)error
{
    if (error != nil) {
        NSAssert(NO, error.localizedDescription);
    }
}

# pragma mark - SBTUITestTunnelClientProtocol -

- (void)launchTunnel
{
    [self.client launchTunnel];
}

- (void)openTunnelWithURL:(NSURL *)url API_AVAILABLE(ios(16.4))
{
    [self.client openTunnelWithURL:url];
}

- (void)launchTunnelWithStartupBlock:(void (^)(void))startupBlock
{
    [self.client launchTunnelWithStartupBlock:startupBlock];
}

- (void)openTunnelWithURL:(NSURL *)url startupBlock:(void (^)(void))startupBlock API_AVAILABLE(ios(16.4))
{
    [self.client openTunnelWithURL:url startupBlock:startupBlock];
}

- (void)launchConnectionless:(NSString * (^)(NSString *, NSDictionary<NSString *,NSString *> *))command
{
    [self.client launchConnectionless:command];
}

- (void)terminate
{
    [self.client terminate];
    
    [super terminate];
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

- (NSString *)stubRequestsMatching:(SBTRequestMatch *)match response:(SBTStubResponse *)response
{
    return [self.client stubRequestsMatching:match response:response];
}

#pragma mark - Stub Remove Commands

- (BOOL)stubRequestsRemoveWithId:(NSString *)stubId
{
    return [self.client stubRequestsRemoveWithId:stubId];
}

- (BOOL)stubRequestsRemoveWithIds:(NSArray<NSString *> *)stubIds
{
    return [self.client stubRequestsRemoveWithIds:stubIds];
}

- (BOOL)stubRequestsRemoveAll
{
    return [self.client stubRequestsRemoveAll];
}

- (NSDictionary<SBTRequestMatch *, SBTStubResponse *> *)stubRequestsAll
{
    return [self.client stubRequestsAll];
}

#pragma mark - Rewrite Commands

- (NSString *)rewriteRequestsMatching:(SBTRequestMatch *)match rewrite:(SBTRewrite *)rewrite
{
    return [self.client rewriteRequestsMatching:match rewrite:rewrite];
}

#pragma mark - Rewrite Remove Commands

- (BOOL)rewriteRequestsRemoveWithId:(NSString *)rewriteId
{
    return [self.client rewriteRequestsRemoveWithId:rewriteId];
}

- (BOOL)rewriteRequestsRemoveWithIds:(NSArray<NSString *> *)rewriteIds
{
    return [self.client rewriteRequestsRemoveWithIds:rewriteIds];
}

- (BOOL)rewriteRequestsRemoveAll
{
    return [self.client rewriteRequestsRemoveAll];
}

#pragma mark - Monitor Requests Commands

- (NSString *)monitorRequestsMatching:(SBTRequestMatch *)match
{
    return [self.client monitorRequestsMatching:match];
}

- (NSArray<SBTMonitoredNetworkRequest *> *)monitoredRequestsPeekAll
{
    return [self.client monitoredRequestsPeekAll];
}

- (NSArray<SBTMonitoredNetworkRequest *> *)monitoredRequestsFlushAll
{
    return [self.client monitoredRequestsFlushAll];
}

- (BOOL)monitorRequestRemoveWithId:(NSString *)reqId
{
    return [self.client monitorRequestRemoveWithId:reqId];
}

- (BOOL)monitorRequestRemoveWithIds:(NSArray<NSString *> *)reqIds
{
    return [self.client monitorRequestRemoveWithIds:reqIds];
}

- (BOOL)monitorRequestRemoveAll
{
    return [self.client monitorRequestRemoveAll];
}

#pragma mark - Synchronously Wait for Requests Commands

- (BOOL)waitForMonitoredRequestsMatching:(SBTRequestMatch *)match timeout:(NSTimeInterval)timeout
{
    return [self.client waitForMonitoredRequestsMatching:match timeout:timeout];
}

- (BOOL)waitForMonitoredRequestsMatching:(SBTRequestMatch *)match timeout:(NSTimeInterval)timeout iterations:(NSUInteger)iterations
{
    return [self.client waitForMonitoredRequestsMatching:match timeout:timeout iterations:iterations];
}

#pragma mark - Throttle Requests Commands

- (NSString *)throttleRequestsMatching:(SBTRequestMatch *)match responseTime:(NSTimeInterval)responseTime
{
    return [self.client  throttleRequestsMatching:match responseTime:responseTime];
}

- (BOOL)throttleRequestRemoveWithId:(NSString *)reqId
{
    return [self.client throttleRequestRemoveWithId:reqId];
}

- (BOOL)throttleRequestRemoveWithIds:(NSArray<NSString *> *)reqIds
{
    return [self.client throttleRequestRemoveWithIds:reqIds];
}

- (BOOL)throttleRequestRemoveAll
{
    return [self.client throttleRequestRemoveAll];
}

#pragma mark - Cookie Block Requests Commands

- (NSString *)blockCookiesInRequestsMatching:(SBTRequestMatch *)match
{
    return [self.client blockCookiesInRequestsMatching:match];
}

- (NSString *)blockCookiesInRequestsMatching:(SBTRequestMatch *)match activeIterations:(NSUInteger)iterations
{
    return [self.client blockCookiesInRequestsMatching:match activeIterations:iterations];
}

- (BOOL)blockCookiesRequestsRemoveWithId:(NSString *)reqId
{
    return [self.client blockCookiesRequestsRemoveWithId:reqId];
}

- (BOOL)blockCookiesRequestsRemoveWithIds:(NSArray<NSString *> *)reqIds
{
    return [self.client blockCookiesRequestsRemoveWithIds:reqIds];
}

- (BOOL)blockCookiesRequestsRemoveAll
{
    return [self.client blockCookiesRequestsRemoveAll];
}

#pragma mark - NSUserDefaults Commands

- (BOOL)userDefaultsSetObject:(id<NSCoding>)object forKey:(NSString *)key
{
    return [self.client userDefaultsSetObject:object forKey:key];
}

- (BOOL)userDefaultsRemoveObjectForKey:(NSString *)key
{
    return [self.client userDefaultsRemoveObjectForKey:key];
}

- (id)userDefaultsObjectForKey:(NSString *)key
{
    return [self.client userDefaultsObjectForKey:key];
}

- (BOOL)userDefaultsReset
{
    return [self.client userDefaultsReset];
}

- (BOOL)userDefaultsSetObject:(id<NSCoding>)object forKey:(NSString *)key suiteName:(NSString *)suiteName
{
    return [self.client  userDefaultsSetObject:object forKey:key suiteName:suiteName];
}

- (BOOL)userDefaultsRemoveObjectForKey:(NSString *)key suiteName:(NSString *)suiteName
{
    return [self.client userDefaultsRemoveObjectForKey:key suiteName:suiteName];
}

- (id)userDefaultsObjectForKey:(NSString *)key suiteName:(NSString *)suiteName
{
    return [self.client userDefaultsObjectForKey:key suiteName:suiteName];
}

- (BOOL)userDefaultsResetSuiteName:(NSString *)suiteName
{
    return [self.client userDefaultsResetSuiteName:suiteName];
}

#pragma mark - NSBundle

- (NSDictionary<NSString *,id> *)mainBundleInfoDictionary
{
    return [self.client mainBundleInfoDictionary];
}

#pragma mark - Copy Commands

- (BOOL)uploadItemAtPath:(NSString *)srcPath toPath:(NSString *)destPath relativeTo:(NSSearchPathDirectory)baseFolder
{
    return [self.client uploadItemAtPath:srcPath toPath:destPath relativeTo:baseFolder];
}

- (NSArray<NSData *> *)downloadItemsFromPath:(NSString *)path relativeTo:(NSSearchPathDirectory)baseFolder
{
    return [self.client downloadItemsFromPath:path relativeTo:baseFolder];
}

#pragma mark - Custom Commands

- (id)performCustomCommandNamed:(NSString *)commandName object:(id)object
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

#pragma mark - XCUITest scroll extensions

- (BOOL)scrollTableViewWithIdentifier:(nonnull NSString *)identifier toRowIndex:(NSInteger)index animated:(BOOL)flag
{
    return [self.client scrollTableViewWithIdentifier:identifier toRowIndex:index animated:flag];
}

- (BOOL)scrollTableViewWithIdentifier:(nonnull NSString *)identifier toElementWithIdentifier:(nonnull NSString *)targetIdentifier animated:(BOOL)flag {
    return [self.client scrollTableViewWithIdentifier:identifier toElementWithIdentifier:targetIdentifier animated:flag];
}


- (BOOL)scrollCollectionViewWithIdentifier:(nonnull NSString *)identifier toElementIndex:(NSInteger)index animated:(BOOL)flag
{
    return [self.client scrollCollectionViewWithIdentifier:identifier toElementIndex:index animated:flag];
}

- (BOOL)scrollCollectionViewWithIdentifier:(nonnull NSString *)identifier toElementWithIdentifier:(nonnull NSString *)targetIdentifier animated:(BOOL)flag {
    return [self.client scrollCollectionViewWithIdentifier:identifier toElementWithIdentifier:targetIdentifier animated:flag];
}

- (BOOL)scrollScrollViewWithIdentifier:(nonnull NSString *)identifier toElementWithIdentifier:(NSString *)targetIdentifier animated:(BOOL)flag
{
    return [self.client scrollScrollViewWithIdentifier:identifier toElementWithIdentifier:targetIdentifier animated:flag];
}

- (BOOL)scrollScrollViewWithIdentifier:(nonnull NSString *)identifier toOffset:(CGFloat)targetOffset animated:(BOOL)flag
{
    return [self.client scrollScrollViewWithIdentifier:identifier toOffset:targetOffset animated:flag];
}


#pragma mark - XCUITest 3D touch extensions

- (BOOL)forcePressViewWithIdentifier:(NSString *)identifier
{
    return [self.client forcePressViewWithIdentifier:identifier];
}

#pragma mark - XCUITest CLLocation extensions

- (BOOL)coreLocationStubEnabled:(BOOL)flag
{
    return [self.client coreLocationStubEnabled:flag];
}

- (BOOL)coreLocationStubAuthorizationStatus:(CLAuthorizationStatus)status
{
    return [self.client coreLocationStubAuthorizationStatus:status];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
- (BOOL)coreLocationStubAccuracyAuthorization:(CLAccuracyAuthorization)authorization API_AVAILABLE(ios(14));
{
    return [self.client coreLocationStubAccuracyAuthorization:authorization];
}
#endif

- (BOOL)coreLocationStubLocationServicesEnabled:(BOOL)flag
{
    return [self.client coreLocationStubLocationServicesEnabled:flag];
}

- (BOOL)coreLocationNotifyLocationUpdate:(nonnull NSArray<CLLocation *>*)locations
{
    return [self.client coreLocationNotifyLocationUpdate:locations];
}

- (BOOL)coreLocationStubManagerLocation:(CLLocation *)location
{
    return [self.client coreLocationStubManagerLocation:location];
}

- (BOOL)coreLocationNotifyLocationError:(nonnull NSError *)error
{
    return [self.client coreLocationNotifyLocationError:error];
}

#pragma mark - XCUITest UNUserNotificationCenter extensions

- (BOOL)notificationCenterStubEnabled:(BOOL)flag API_AVAILABLE(ios(10.0))
{
    return [self.client notificationCenterStubEnabled:flag];
}

- (BOOL)notificationCenterStubAuthorizationStatus:(UNAuthorizationStatus)status API_AVAILABLE(ios(10.0))
{
    return [self.client notificationCenterStubAuthorizationStatus:status];
}

#pragma mark - XCUITest WKWebView stubbing

- (BOOL)wkWebViewStubEnabled:(BOOL)flag
{
    return [self.client wkWebViewStubEnabled:flag];
}

@end
