// SBTUITunneledApplication.h
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

#import <XCTest/XCTest.h>
#import "SBTUITestTunnel.h"

@interface SBTUITunneledApplication : XCUIApplication

/**
 *  Launch application synchronously waiting for the tunnel server connection to be established.
 */
- (void)launchTunnel;

/**
 *  Launch application synchronously waiting for the tunnel server connection to be established.
 *
 *  @param startupBlock Block that is executed before connection is estabilished. 
 *  Useful to inject startup condition (user settings, preferences).
 *  Note: commands sent in the completionBlock will return nil
 */
- (void)launchTunnelWithStartupBlock:(nullable void (^)(void))startupBlock;

/**
 *  Launch application synchronously waiting for the tunnel server connection to be established.
 *
 *  @param options List of options to be passed on launch.
 *  Valid options:
 *  SBTUITunneledApplicationLaunchOptionResetFilesystem: delete app's filesystem sandbox
 *  SBTUITunneledApplicationLaunchOptionInhibitCoreLocation: will disable CoreLocation on app side. 
 *  This is useful when you want to get rid from the initial authorization popups which may be tricky to handle otherwise.
 *
 *  @param startupBlock Block that is executed before connection is estabilished.
 *  Useful to inject startup condition (user settings, preferences).
 *  Note: commands sent in the completionBlock will return nil
 */
- (void)launchTunnelWithOptions:(nonnull NSArray<NSString *> *)options startupBlock:(nullable void (^)(void))startupBlock;

#pragma mark - Stub Commands

/**
 *  Stub a request matching a regular expression pattern. The rule is checked against the URL.absoluteString of the request
 *
 *  Note: you cannot have a monitor request and a stub request that matches the same regex active at the same time, the last added will be skipped.
 *
 *  @param regexPattern The regular expression
 *  @param returnJsonDcitionary An NSDictionary<NSString *, NSObject *> * to be returned as JSON
 *  @param returnCode The HTTP response code to be returned
 *  @param responseTime If positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
 *
 *  @return If nil request failed. Otherwise an identifier associated to the newly created stub. Should be used when removing stub using -(BOOL)stubRequestsRemoveWithId:
 */
- (nullable NSString *)stubRequestsWithRegex:(nonnull NSString *)regexPattern returnJsonDictionary:(nonnull NSDictionary<NSString *, NSObject *> *)json returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime;

/**
*  Stub a request whose request parameters match the specified list.
*  Params can be either key only: @[@"param1", @"param2"...] in which case we'll just check for the key 
*  or key + value @[@"param1=value1", @"param2=value2"...] in which case we'll check that also the value
 *
 *  Note: you cannot have a monitor request and a stub request that matches the same regex active at the same time, the last added will be skipped.
 *
*  @param queryParams The list of query params that should be present in the request
*  @param returnJsonDictionary An NSDictionary<NSString *, NSObject *> * to be returned as JSON
*  @param returnCode The HTTP response code to be returned
*  @param responseTime If positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
*
*  @return If nil request failed. Otherwise an identifier associated to the newly created stub. Should be used when removing stub using -(BOOL)stubRequestsRemoveWithId:
*/
- (nullable NSString *)stubRequestsWithQueryParams:(nonnull NSArray<NSString *> *)queryParams returnJsonDictionary:(nonnull NSDictionary<NSString *, NSObject *> *)json returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime;

/**
 *  Stub a request matching a regular expression pattern. The rule is checked against the URL.absoluteString of the request
 *
 *  Note: you cannot have a monitor request and a stub request that matches the same regex active at the same time, the last added will be skipped.
 *
 *  @param regexPattern The regular expression
 *  @param returnJsonNamed The filename of a file in bundle to be returned as JSON
 *  @param returnCode The HTTP response code to be returned
 *  @param responseTime If positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
 *
 *  @return If nil request failed. Otherwise an identifier associated to the newly created stub. Should be used when removing stub using -(BOOL)stubRequestsRemoveWithId:
 */
- (nullable NSString *)stubRequestsWithRegex:(nonnull NSString *)regexPattern returnJsonNamed:(nonnull NSString *)jsonFilename returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime;

/**
 *  Stub a request whose request parameters match the specified list.
 *  Params can be either key only: @[@"param1", @"param2"...] in which case we'll just check for the key
 *  or key + value @[@"param1=value1", @"param2=value2"...] in which case we'll check that also the value
 *
 *  Note: you cannot have a monitor request and a stub request that matches the same regex active at the same time, the last added will be skipped.
 *
 *  @param queryParams The list of query params that should be present in the request
 *  @param returnJsonNamed The filename of a file in bundle to be returned as JSON
 *  @param returnCode The HTTP response code to be returned
 *  @param responseTime If positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
 *
 *  @return If nil request failed. Otherwise an identifier associated to the newly created stub. Should be used when removing stub using -(BOOL)stubRequestsRemoveWithId:
 */
- (nullable NSString *)stubRequestsWithQueryParams:(nonnull NSArray<NSString *> *)queryParams returnJsonNamed:(nonnull NSString *)jsonFilename returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime;

#pragma mark - Stub And Remove Commands

/**
 *  Stub a request matching a regular expression pattern for a limited number of times. The rule is checked against the URL.absoluteString of the request
 *
 *  Note: you cannot have a monitor request and a stub request that matches the same regex active at the same time, the last added will be skipped.
 *
 *  @param regexPattern The regular expression
 *  @param returnJsonDcitionary An NSDictionary<NSString *, NSObject *> * to be returned as JSON
 *  @param returnCode The HTTP response code to be returned
 *  @param responseTime If positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
 *  @param iterations number of matches after which the stub will be automatically removed
 *
 *  @return `YES` on success.
 */
- (BOOL)stubRequestsWithRegex:(nonnull NSString *)regexPattern returnJsonDictionary:(nonnull NSDictionary<NSString *, NSObject *> *)json returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime removeAfterIterations:(NSUInteger)iterations;

/**
 *  Stub a request whose request parameters match the specified list for a limited number of times.
 *  Params can be either key only: @[@"param1", @"param2"...] in which case we'll just check for the key
 *  or key + value @[@"param1=value1", @"param2=value2"...] in which case we'll check that also the value
 *
 *  Note: you cannot have a monitor request and a stub request that matches the same regex active at the same time, the last added will be skipped.
 *
 *  @param queryParams The list of query params that should be present in the request
 *  @param returnJsonDictionary An NSDictionary<NSString *, NSObject *> * to be returned as JSON
 *  @param returnCode The HTTP response code to be returned
 *  @param responseTime If positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
 *
 *  @return `YES` on success.
 */
- (BOOL)stubRequestsWithQueryParams:(nonnull NSArray<NSString *> *)queryParams returnJsonDictionary:(nonnull NSDictionary<NSString *, NSObject *> *)json returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime removeAfterIterations:(NSUInteger)iterations;

/**
 *  Stub a request matching a regular expression pattern for a limited number of times. The rule is checked against the URL.absoluteString of the request
 *
 *  Note: you cannot have a monitor request and a stub request that matches the same regex active at the same time, the last added will be skipped.
 *
 *  @param regexPattern The regular expression
 *  @param returnJsonNamed The filename of a file in bundle to be returned as JSON
 *  @param returnCode The HTTP response code to be returned
 *  @param responseTime If positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
 *
 *  @return `YES` on success.
 */
- (BOOL)stubRequestsWithRegex:(nonnull NSString *)regexPattern returnJsonNamed:(nonnull NSString *)jsonFilename returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime removeAfterIterations:(NSUInteger)iterations;

/**
 *  Stub a request whose request parameters match the specified list for a limited number of times.
 *  Params can be either key only: @[@"param1", @"param2"...] in which case we'll just check for the key
 *  or key + value @[@"param1=value1", @"param2=value2"...] in which case we'll check that also the value
 *
 *  Note: you cannot have a monitor request and a stub request that matches the same regex active at the same time, the last added will be skipped.
 *
 *  @param queryParams The list of query params that should be present in the request
 *  @param returnJsonNamed The filename of a file in bundle to be returned as JSON
 *  @param returnCode The HTTP response code to be returned
 *  @param responseTime If positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
 *
 *  @return `YES` on success.
 */
- (BOOL)stubRequestsWithQueryParams:(nonnull NSArray<NSString *> *)queryParams returnJsonNamed:(nonnull NSString *)jsonFilename returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime removeAfterIterations:(NSUInteger)iterations;

#pragma mark - Stub Remove Commands

/**
 *  Remove a specific stub
 *
 *  @param stubId The identifier that was returned when adding the stub
 *
 *  @return `YES` on success. If `NO` the specified identifier wasn't associated to an active stub or request failed
 */
- (BOOL)stubRequestsRemoveWithId:(nonnull NSString *)stubId;

/**
 *  Remove a list of stubs
 *
 *  @param stubIds The identifiers that were returned when adding the stub
 *
 *  @return `YES` on success. If `NO` one of the specified identifier were not associated to an active stub or request failed
 */
- (BOOL)stubRequestsRemoveWithIds:(nonnull NSArray<NSString *> *)stubIds;

/**
 *  Remove all active stubs
 *
 *  @return `YES` on success.
 */
- (BOOL)stubRequestsRemoveAll;

#pragma mark - Monitor Requests Commands

/**
 *  Start monitoring requests matching a regular expression pattern. The rule is checked against the URL.absoluteString of the request.
 *
 *  The monitored events can be successively polled using the monitoredRequestsFlushAll method.
 *
 *  Note: you cannot have a monitor request and a stub request that matches the same regex active at the same time, the last added will be skipped.
 *
 *  @param regexPattern The regular expression
 *
 *  @return If nil request failed. Otherwise an identifier associated to the newly created monitor probe. Should be used when using -(BOOL)monitorRequestRemoveWithId:
 */
- (nullable NSString *)monitorRequestsWithRegex:(nonnull NSString *)regexPattern;

/**
 *  Start monitoring requests whose parameters match the specified list.
 *  Params can be either key only: @[@"param1", @"param2"...] in which case we'll just check for the key
 *  or key + value @[@"param1=value1", @"param2=value2"...] in which case we'll check that also the value
 *
 *  The monitored events can be successively polled using the monitoredRequestsFlushAll method.
 *
 *  Note: you cannot have a monitor request and a stub request that matches the same regex active at the same time, the last added will be skipped.
 *
 *  @param queryParams The list of query params that should be present in the request
 *
 *  @return If nil request failed. Otherwise an identifier associated to the newly created monitor probe. Should be used when using -(BOOL)monitorRequestRemoveWithId:
 */
- (nullable NSString *)monitorRequestsWithQueryParams:(nonnull NSArray<NSString *> *)queryParams;

/**
 *  Peek (retrieve) the current list of collected requests
 *
 *  @return The list of monitored requests
 */
- (nonnull NSArray<SBTMonitoredNetworkRequest *> *)monitoredRequestsPeekAll;

/**
 *  Flushes (retrieve + clear) the current list of collected requests
 *
 *  @return The list of monitored requests
 */
- (nonnull NSArray<SBTMonitoredNetworkRequest *> *)monitoredRequestsFlushAll;

/**
 *  Remove a request monitor
 *
 *  @param reqId The identifier that was returned when adding the monitor request
 *
 *  @return `YES` on success. If `NO` one of the specified identifier was not associated to an active monitor request or request failed
 */
- (BOOL)monitorRequestRemoveWithId:(nonnull NSString *)reqId;

/**
 *  Remove a list of request monitors
 *
 *  @param reqIds The identifiers that were returned when adding the monitor requests
 *
 *  @return `YES` on success. If `NO` one of the specified identifier were not associated to an active monitor request or request failed
 */
- (BOOL)monitorRequestRemoveWithIds:(nonnull NSArray<NSString *> *)reqIds;

/**
 *  Remove all active request monitors
 *
 *  @return `YES` on success.
 */
- (BOOL)monitorRequestRemoveAll;

#pragma mark - Throttle Requests Commands

/**
 *  Start throttling requests matching a regular expression pattern. The rule is checked against the URL.absoluteString of the request.
 *
 *  The throttled events can be successively polled using the throttledRequestsFlushAll method.
 *
 *  Note: you cannot have a throttle request and a stub request that matches the same regex active at the same time, the last added will be skipped.
 *
 *  @param regexPattern The regular expression
 *  @param responseTime If positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
 *
 *  @return If nil request failed. Otherwise an identifier associated to the newly created throttle request. Should be used when using -(BOOL)throttleRequestRemoveWithId:
 */
- (nullable NSString *)throttleRequestsWithRegex:(nonnull NSString *)regexPattern responseTime:(NSTimeInterval)responseTime;

/**
 *  Start throttling requests whose parameters match the specified list.
 *  Params can be either key only: @[@"param1", @"param2"...] in which case we'll just check for the key
 *  or key + value @[@"param1=value1", @"param2=value2"...] in which case we'll check that also the value
 *s
 *  The throttled events can be successively polled using the throttledRequestsFlushAll method.
 *
 *  Note: you cannot have a throttle request and a stub request that matches the same regex active at the same time, the last added will be skipped.
 *
 *  @param queryParams The list of query params that should be present in the request
 *  @param responseTime If positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
 *
 *  @return If nil request failed. Otherwise an identifier associated to the newly created throttle request. Should be used when using -(BOOL)throttleRequestRemoveWithId:
 */
- (nullable NSString *)throttleRequestsWithQueryParams:(nonnull NSArray<NSString *> *)queryParams responseTime:(NSTimeInterval)responseTime;

/**
 *  Remove a request throttle
 *
 *  @param reqId The identifier that was returned when adding the throttle request
 *
 *  @return `YES` on success. If `NO` one of the specified identifier was not associated to an active throttle request or request failed
 */
- (BOOL)throttleRequestRemoveWithId:(nonnull NSString *)reqId;

/**
 *  Remove a list of request throttles
 *
 *  @param reqIds The identifiers that were returned when adding the throttle requests
 *
 *  @return `YES` on success. If `NO` one of the specified identifier were not associated to an active throttle request or request failed
 */
- (BOOL)throttleRequestRemoveWithIds:(nonnull NSArray<NSString *> *)reqIds;

/**
 *  Remove all active request throttles
 *
 *  @return `YES` on success.
 */
- (BOOL)throttleRequestRemoveAll;

#pragma mark - NSUserDefaults Commands

/**
 *  Add object to NSUSerDefaults.
 *
 *  @param object Object to be added
 *  @param key Key associated to object
 *
 *  @return `YES` on success.
 */
- (BOOL)userDefaultsSetObject:(nonnull NSObject<NSCoding> *)object forKey:(nonnull NSString *)key;

/**
 *  Remove object from NSUSerDefaults.
 *
 *  @param object Object to be added
 *  @param key Key associated to object
 *
 *  @return `YES` on success.
 */
- (BOOL)userDefaultsRemoveObjectForKey:(nonnull NSString *)key;

/**
 *  Get object from NSUserDefaults
 *
 *  @param key Key associated to object
 *
 *  @return The retrieved object.
 */
- (nullable id)userDefaultsObjectForKey:(nonnull NSString *)key;

/**
 *  Reset NSUserDefaults
 *
 *  @return `YES` on success.
 */
- (BOOL)userDefaultsReset;

#pragma mark - Keychain Commands

/**
 *  Add object to keychain. For simplicity we're using FXKeychain using the BunleID as default service
 *
 *  @param object Object to be added
 *  @param key Key associated to object
 *
 *  @return `YES` on success.
 */
- (BOOL)keychainSetObject:(nonnull NSObject<NSCoding> *)object forKey:(nonnull NSString *)key;

/**
 *  Remove object from keychain. For simplicity we're using FXKeychain using the BunleID as default service
 *
 *  @param key Key associated to object
 *
 *  @return `YES` on success.
 */
- (BOOL)keychainRemoveObjectForKey:(nonnull NSString *)key;

/**
 *  Get object from keychain. For simplicity we're using FXKeychain using the BunleID as default service
 *
 *  @param key Key associated to object
 *
 *  @return The retrieved object.
 */
- (nullable id)keychainObjectForKey:(nonnull NSString *)key;

/**
 *  Reset Keychain
 *
 *  @return `YES` on success.
 */
- (BOOL)keychainReset;

#pragma mark - Copy Commands

/**
 *  Upload item to remote host
 *
 *  @param srcPath source path
 *  @param destPath destination path relative to baseFolder
 *  @param baseFolder base folder for destPath
 *
 *  @return `YES` on success.
 */
- (BOOL)uploadItemAtPath:(nonnull NSString *)srcPath toPath:(nullable NSString *)destPath relativeTo:(NSSearchPathDirectory)baseFolder;

/**
 *  Download item from remote host
 *
 *  @param path source path
 *  @param destPath destination path relative to baseFolder
 *  @param baseFolder base folder for destPath
 *
 *  @return The data associated to the requested item
 */
- (nullable NSData *)downloadItemFromPath:(nonnull NSString *)path relativeTo:(NSSearchPathDirectory)baseFolder;

#pragma mark - Custom Commands

/**
 *  Perform custom command.
 *
 *  @param commandName custom name that will match [SBTUITestTunnelServer registerCustomCommandNamed:block:]
 *  @param data optional data to be attached to request
 *
 *  @return `YES` on success.
 */
- (BOOL)performCustomCommandNamed:(nonnull NSString *)commandName object:(nullable NSObject<NSCoding> *)object;

#pragma mark - Other Commands

/**
 *  Set user iterface animations. Should imporve test execution speed When enabled
 *
 *  @param enabled enable animations
 *
 *  @return `YES` on success.
 */
- (BOOL)setUserInterfaceAnimationsEnabled:(BOOL)enabled;

@end

#endif
