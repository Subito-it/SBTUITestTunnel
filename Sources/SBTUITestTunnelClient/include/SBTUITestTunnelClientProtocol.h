// SBTUITestTunnelClientProtocol.h
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

@import SBTUITestTunnelCommon;
@import CoreLocation;
@import UserNotifications;

@class SBTRequestMatch;
@class SBTStubResponse;
@class SBTRewrite;

@protocol SBTUITestTunnelClientProtocol <NSObject>

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
 *  @param retryThreshold Number of additional launch attempts if initial attempt fails (0 means no retries)
 *
 *  @param retryInterval Time interval in seconds to wait between retry attempts
 *
 *  @param startupBlock Block that is executed before connection is estabilished.
 *  Useful to inject startup condition (user settings, preferences).
 *  Note: commands sent in the completionBlock will return nil
 */
- (void)launchTunnelWithRetries:(NSInteger)retryThreshold retryInterval:(NSTimeInterval)retryInterval startupBlock:(nullable void (^)(void))startupBlock;

/**
 *  Internal, don't use.
 */
- (void)launchConnectionless:(nonnull NSString * _Nonnull (^)(NSString * _Nonnull, NSDictionary<NSString *, NSString *> * _Nonnull))command;

/**
 * Terminates the tunnel by tidying up the internal state. Informs the delegate once complete so that the delegate can then terminate the application.
 */
- (void)terminate;

#pragma mark - Timeout

/**
 *  Change the default timeout for the tunnel connection. Should be used only as a workaround when using the tunnel on very slow hardwares
 *
 *  @param timeout Timeout in seconds
 */
+ (void)setConnectionTimeout:(NSTimeInterval)timeout;

#pragma mark - Quit Command

/**
 *  Quits application by sending an abort(). Useful to use in tearDown() to make sure the current test ends
 */
- (void)quit;

#pragma mark - Stub Commands

/**
 *  Stub a request matching a regular expression pattern. The rule is checked against the URL.absoluteString of the request
 *
 *  @param match The match object that contains the matching rules
 *  @param response The object that represents the stubbed response
 *
 *  @return If nil request failed. Otherwise an identifier associated to the newly created stub. Should be used when removing stub using -(BOOL)stubRequestsRemoveWithId:
 */
- (nullable NSString *)stubRequestsMatching:(nonnull SBTRequestMatch *)match response:(nonnull SBTStubResponse *)response;

#pragma mark - Stub Remove Commands

/**
 *  Remove a specific stub
 *
 *  @param stubId The identifier that was returned when adding the stub
 *
 *  @return `YES` on success If `NO` the specified identifier wasn't associated to an active stub or request failed
 */
- (BOOL)stubRequestsRemoveWithId:(nonnull NSString *)stubId NS_SWIFT_NAME(stubRequestsRemove(id:));

/**
 *  Remove a list of stubs
 *
 *  @param stubIds The identifiers that were returned when adding the stub
 *
 *  @return `YES` on success If `NO` one of the specified identifier were not associated to an active stub or request failed
 */
- (BOOL)stubRequestsRemoveWithIds:(nonnull NSArray<NSString *> *)stubIds NS_SWIFT_NAME(stubRequestsRemove(ids:));

/**
 *  Remove stubs matching a specified request match
 *
 *  @param match The match object associated to the stub to be removed
 *
 *  @return `YES` on success If `NO` the specified matching rule was not associated to any active stubs or request failed
 */
- (BOOL)stubRequestsRemoveWithRequestMatch:(nonnull SBTRequestMatch *)match NS_SWIFT_NAME(stubRequestsRemove(requestMatch:));

/**
 *  Remove all active stubs
 *
 *  @return `YES` on success
 */
- (BOOL)stubRequestsRemoveAll;

/**
 *  Returns all active stubs
 *
 *  @return An array containing all active stubs
 */
- (nonnull NSArray<SBTActiveStub *> *)stubRequestsAll;

#pragma mark - Rewrite Commands

/**
 *  Rewrite a request matching a regular expression pattern. The rule is checked against the SBTRequestMatch object
 *
 *  @param match The match object that contains the matching rules
 *  @param rewrite The object that represents the rewrite rules
 *
 *  @return If nil request failed. Otherwise an identifier associated to the newly created rewrite. Should be used when removing rewrite using -(BOOL)rewriteRequestsRemoveWithId:
 */
- (nullable NSString *)rewriteRequestsMatching:(nonnull SBTRequestMatch *)match rewrite:(nonnull SBTRewrite *)rewrite;

#pragma mark - Rewrite Remove Commands

/**
 *  Remove a specific rewrite
 *
 *  @param rewriteId The identifier that was returned when adding the rewrite
 *
 *  @return `YES` on success If `NO` the specified identifier wasn't associated to an active rewrite or request failed
 */
- (BOOL)rewriteRequestsRemoveWithId:(nonnull NSString *)rewriteId;

/**
 *  Remove a list of rewrites
 *
 *  @param rewriteIds The identifiers that were returned when adding the rewrite
 *
 *  @return `YES` on success If `NO` one of the specified identifier were not associated to an active rewrite or request failed
 */
- (BOOL)rewriteRequestsRemoveWithIds:(nonnull NSArray<NSString *> *)rewriteIds;

/**
 *  Remove all active rewrites
 *
 *  @return `YES` on success
 */
- (BOOL)rewriteRequestsRemoveAll;

#pragma mark - Monitor Requests Commands

/**
 *  Start monitoring requests matching a regular expression pattern. The rule is checked against the SBTRequestMatch object
 *
 *  The monitored events can be successively polled using the monitoredRequestsFlushAll method.
 *
 *  @param match The match object that contains the matching rules
 *
 *  @return If nil request failed. Otherwise an identifier associated to the newly created monitor probe. Should be used when using -(BOOL)monitorRequestRemoveWithId:
 */
- (nullable NSString *)monitorRequestsMatching:(nonnull SBTRequestMatch *)match;

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
 *  @return `YES` on success If `NO` one of the specified identifier was not associated to an active monitor request or request failed
 */
- (BOOL)monitorRequestRemoveWithId:(nonnull NSString *)reqId;

/**
 *  Remove a list of request monitors
 *
 *  @param reqIds The identifiers that were returned when adding the monitor requests
 *
 *  @return `YES` on success If `NO` one of the specified identifier were not associated to an active monitor request or request failed
 */
- (BOOL)monitorRequestRemoveWithIds:(nonnull NSArray<NSString *> *)reqIds;

/**
 *  Remove all active request monitors
 *
 *  @return `YES` on success
 */
- (BOOL)monitorRequestRemoveAll;

#pragma mark - Synchronously Wait for Requests Commands

/**
 *  Synchronously wait for a request to happen once on the app target. The rule is checked against the SBTRequestMatch object
 *
 *  Note: you have to start a monitor request before calling this method
 *
 *  @param match The match object that contains the matching rules. The method will look if the specified rules match the existing monitored requests
 *  @param timeout How long to wait for the request to happen
 *
 *  @return `YES` on success, `NO` on timeout
 */
- (BOOL)waitForMonitoredRequestsMatching:(nonnull SBTRequestMatch *)match timeout:(NSTimeInterval)timeout;

/**
 *  Synchronously wait for a request to happen a certain number of times on the app target. The rule is checked against the SBTRequestMatch object
 *
 *  Note: you have to start a monitor request before calling this method
 *
 *  @param match The match object that contains the matching rules. The method will look if the specified rules match the existing monitored requests
 *  @param timeout How long to wait for the request to happen
 *  @param iterations How often the request should happen before timing out
 *
 *  @return `YES` on success, `NO` on timeout
 */
- (BOOL)waitForMonitoredRequestsMatching:(nonnull SBTRequestMatch *)match timeout:(NSTimeInterval)timeout iterations:(NSUInteger)iterations;

#pragma mark - Throttle Requests Commands

/**
 *  Start throttling requests matching a regular expression pattern. The rule is checked against the SBTRequestMatch object
 *
 *  The throttled events can be successively polled using the throttledRequestsFlushAll method.
 *
 *  @param match The match object that contains the matching rules
 *  @param responseTime If positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
 *
 *  @return If nil request failed. Otherwise an identifier associated to the newly created throttle request. Should be used when using -(BOOL)throttleRequestRemoveWithId:
 */
- (nullable NSString *)throttleRequestsMatching:(nonnull SBTRequestMatch *)match responseTime:(NSTimeInterval)responseTime;

/**
 *  Remove a request throttle
 *
 *  @param reqId The identifier that was returned when adding the throttle request
 *
 *  @return `YES` on success If `NO` one of the specified identifier was not associated to an active throttle request or request failed
 */
- (BOOL)throttleRequestRemoveWithId:(nonnull NSString *)reqId;

/**
 *  Remove a list of request throttles
 *
 *  @param reqIds The identifiers that were returned when adding the throttle requests
 *
 *  @return `YES` on success If `NO` one of the specified identifier were not associated to an active throttle request or request failed
 */
- (BOOL)throttleRequestRemoveWithIds:(nonnull NSArray<NSString *> *)reqIds;

/**
 *  Remove all active request throttles
 *
 *  @return `YES` on success
 */
- (BOOL)throttleRequestRemoveAll;

#pragma mark - Cookie Block Requests Commands

/**
 *  Block all cookies found in requests matching a regular expression pattern. The rule is checked against the SBTRequestMatch object
 *
 *  @param match The match object that contains the matching rules
 *
 *  @return If nil request failed. Otherwise an identifier associated to the newly created throttle request. Should be used when using -(BOOL)throttleRequestRemoveWithId:
 */
- (nullable NSString *)blockCookiesInRequestsMatching:(nonnull SBTRequestMatch *)match;

/**
 *  Block all cookies found in requests matching a regular expression pattern. The rule is checked against the SBTRequestMatch object
 *
 *  @param match The match object that contains the matching rules
 *  @param activeIterations The number of times the cookies are blocked
 *
 *  @return If nil request failed. Otherwise an identifier associated to the newly created throttle request. Should be used when using -(BOOL)throttleRequestRemoveWithId:
 */
- (nullable NSString *)blockCookiesInRequestsMatching:(nonnull SBTRequestMatch *)match activeIterations:(NSUInteger)activeIterations;

/**
 *  Remove a cookie block request
 *
 *  @param reqId The identifier that was returned when adding the cookie block request
 *
 *  @return `YES` on success If `NO` one of the specified identifier was not associated to an active cookie block request or request failed
 */
- (BOOL)blockCookiesRequestsRemoveWithId:(nonnull NSString *)reqId;

/**
 *  Remove a list of cookie block requests
 *
 *  @param reqIds The identifiers that were returned when adding the cookie block requests
 *
 *  @return `YES` on success If `NO` one of the specified identifier were not associated to an active cookie block request or request failed
 */
- (BOOL)blockCookiesRequestsRemoveWithIds:(nonnull NSArray<NSString *> *)reqIds;

/**
 *  Remove all cookie block requests
 *
 *  @return `YES` on success
 */
- (BOOL)blockCookiesRequestsRemoveAll;

#pragma mark - NSUserDefaults Commands

/**
 *  Add object to NSUSerDefaults.
 *
 *  @param object Object to be added
 *  @param key Key associated to object
 *
 *  @return `YES` on success
 */
- (BOOL)userDefaultsSetObject:(nonnull id<NSCoding>)object forKey:(nonnull NSString *)key;

/**
 *  Remove object from NSUSerDefaults.
 *
 *  @param key Key associated to object
 *
 *  @return `YES` on success
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
 *  @return `YES` on success
 */
- (BOOL)userDefaultsReset;

/**
 *  Add object to NSUSerDefaults.
 *
 *  @param object Object to be added
 *  @param key Key associated to object
 *  @param suiteName user defaults database name
 *
 *  @return `YES` on success
 */
- (BOOL)userDefaultsSetObject:(nonnull id<NSCoding>)object forKey:(nonnull NSString *)key suiteName:(nonnull NSString *)suiteName;

/**
 *  Remove object from NSUSerDefaults.
 *
 *  @param key Key associated to object
 *  @param suiteName user defaults database name
 *
 *  @return `YES` on success
 */
- (BOOL)userDefaultsRemoveObjectForKey:(nonnull NSString *)key suiteName:(nonnull NSString *)suiteName;

/**
 *  Get object from NSUserDefaults
 *
 *  @param key Key associated to object
 *  @param suiteName user defaults database name
 *
 *  @return The retrieved object.
 */
- (nullable id)userDefaultsObjectForKey:(nonnull NSString *)key suiteName:(nonnull NSString *)suiteName;

/**
 *  Reset NSUserDefaults
 *
 *  @param suiteName user defaults database name
 *  @return `YES` on success
 */
- (BOOL)userDefaultsResetSuiteName:(nonnull NSString *)suiteName;

#pragma mark - NSBundle

- (nullable NSDictionary<NSString *, id> *)mainBundleInfoDictionary;

#pragma mark - Copy Commands

/**

 *  Upload item to remote host
 *
 *  @param srcPath source path
 *  @param destPath destination path relative to baseFolder
 *  @param baseFolder base folder for destPath
 *
 *  @return `YES` on success
 */
- (BOOL)uploadItemAtPath:(nonnull NSString *)srcPath toPath:(nullable NSString *)destPath relativeTo:(NSSearchPathDirectory)baseFolder;

/**
 *  Download one or more files from remote host
 *
 *  @param path source path (may include wildcard *, i.e ('*.jpg')
 *  @param baseFolder base folder for destPath
 *
 *  @return The data associated to the requested item
 */
- (nullable NSArray<NSData *> *)downloadItemsFromPath:(nonnull NSString *)path relativeTo:(NSSearchPathDirectory)baseFolder;

#pragma mark - Custom Commands

/**
 *  Perform custom command.
 *
 *  @param commandName custom name that will match [SBTUITestTunnelServer registerCustomCommandNamed:block:]
 *  @param object optional data to be attached to request
 *
 *  @return object returned from custom block
 */
- (nullable id)performCustomCommandNamed:(nonnull NSString *)commandName object:(nullable id)object;

#pragma mark - Other Commands

/**
 *  Set user iterface animations through [UIView setAnimationsEnabled:]. Should imporve test execution speed When enabled
 *  Sometimes useful as per https://forums.developer.apple.com/thread/6503
 *
 *  @param enabled enable animations
 *
 *  @return `YES` on success
 */
- (BOOL)setUserInterfaceAnimationsEnabled:(BOOL)enabled;

/**
 *  Get user iterface animations through [UIView setAnimationsEnabled:]. Should imporve test execution speed When enabled
 *  Sometimes useful as per https://forums.developer.apple.com/thread/6503
 *
 *  @return `YES` on when animations are enabled
 */
- (BOOL)userInterfaceAnimationsEnabled;

/**
 *  Set user iterface animations through UIApplication.sharedApplication.keyWindow.layer.speed. Should imporve test execution speed When enabled
 *
 *  @param speed speed of animation animations
 *
 *  @return `YES` on success
 */
- (BOOL)setUserInterfaceAnimationSpeed:(NSInteger)speed;

/**
 *  Get user iterface animations through UIApplication.sharedApplication.keyWindow.layer.speed. Should imporve test execution speed When enabled
 *
 *  @return current animation speed
 */
- (NSInteger)userInterfaceAnimationSpeed;

#pragma mark - XCUITest scroll extensions

/**
 *  Scroll UITablewViews view to the specified row (flattening sections if any).
 *
 *  @param identifier accessibilityIdentifier of the UITableView
 *  @param index the index of the row to scroll the element to. This value flattens sections (if more than one is returned by the dataSource) and is best effort meaning it will stop at the last cell if the passed number if larger than the available cells. Passing NSIntegerMax guarantees to scroll to last cell.
 *  @param flag pass YES to animate the scroll; otherwise, pass NO
 *
 *  @return `YES` on success
 */
- (BOOL)scrollTableViewWithIdentifier:(nonnull NSString *)identifier toRowIndex:(NSInteger)index animated:(BOOL)flag;

/**
 *  Scroll UITablewViews view to the specified row (flattening sections if any).
 *
 *  @param identifier accessibilityIdentifier of the UITableView
 *  @param targetIdentifier accessibilityIdentifier of the element the table view should scroll to
 *  @param flag pass YES to animate the scroll; otherwise, pass NO
 *
 *  @return `YES` on success
 */
- (BOOL)scrollTableViewWithIdentifier:(nonnull NSString *)identifier toElementWithIdentifier:(nonnull NSString *)targetIdentifier animated:(BOOL)flag;

/**
 *  Scroll UICollection view to the specified row (flattening sections if any).
 *
 *  @param identifier accessibilityIdentifier of the UICollectionView
 *  @param index the index of the element to scroll the element to. This value flattens sections (if more than one is returned by the dataSource) and is best effort meaning it will stop at the last cell if the passed number if larger than the available cells. Passing NSIntegerMax guarantees to scroll to last cell.
 *  @param flag pass YES to animate the scroll; otherwise, pass NO
 *
 *  @return `YES` on success
*/
- (BOOL)scrollCollectionViewWithIdentifier:(nonnull NSString *)identifier toElementIndex:(NSInteger)index animated:(BOOL)flag;

/**
 *  Scroll UICollection view to the specified row (flattening sections if any).
 *
 *  @param identifier accessibilityIdentifier of the UICollectionView
 *  @param targetIdentifier accessibilityIdentifier of the element the collection view should scroll to
 *  @param flag pass YES to animate the scroll; otherwise, pass NO
 *
 *  @return `YES` on success
*/
- (BOOL)scrollCollectionViewWithIdentifier:(nonnull NSString *)identifier toElementWithIdentifier:(nonnull NSString *)targetIdentifier animated:(BOOL)flag;

/**
 *  Scroll UIScrollView view to the specified element
 *
 *  @param identifier accessibilityIdentifier of the UIScrollView
 *  @param targetIdentifier accessibilityIdentifier of the element the scroll view should scroll to
 *  @param flag pass YES to animate the scroll; otherwise, pass NO
 *
 *  @return `YES` on success
 */
- (BOOL)scrollScrollViewWithIdentifier:(nonnull NSString *)identifier toElementWithIdentifier:(nonnull NSString *)targetIdentifier animated:(BOOL)flag;


/**
 *  Scroll UIScrollView view to the specified normalized offset
 *
 *  @param identifier accessibilityIdentifier of the UIScrollView
 *  @param targetOffset the normalized targetOffset
 *  @param flag pass YES to animate the scroll; otherwise, pass NO
 *
 *  @return `YES` on success
 */
- (BOOL)scrollScrollViewWithIdentifier:(nonnull NSString *)identifier toOffset:(CGFloat)targetOffset animated:(BOOL)flag;

#pragma mark - XCUITest 3D touch extensions

/**
 *  Perform force touch pop interaction on the specified element
 *
 *  @param identifier accessibilityIdentifier of the element to force press
 *
 *  @return `YES` on success
 */
- (BOOL)forcePressViewWithIdentifier:(nonnull NSString *)identifier;

#pragma mark - XCUITest CLLocation extensions

/**
 *  Enable CLLocationManager stubbing
 *
 *  All calls to `CLLocationManagerDelegate` methods will be invoked on the `Main` thread, simplifying the requirements for [`CLLocationManager`](https://developer.apple.com/documentation/corelocation/cllocationmanager) :
 *
 *  _Core Location calls the methods of your delegate object using the NSRunLoop of the thread on which you initialized the CLLocationManager object. That thread must itself have an active NSRunLoop, like the one found in your app’s main thread._
 *
 *  @param flag stubbing status
 *
 *  @return `YES` on success
*/
- (BOOL)coreLocationStubEnabled:(BOOL)flag;

/**
 *  Stub CLLocationManager authorizationStatus
 *
 *  @param status location authorization status. The default value returned by `+[CLLocationManager authorizationStatus]` when enabling core location stubbing is `kCLAuthorizationStatusAuthorizedAlways`
 *
 *  The `CLLocationManagerDelegate` methods: `locationManager:didChangeAuthorizationStatus:` and `locationManagerDidChangeAuthorization:` will be called on the `Main` thread.
 *
 *  @return `YES` on success
*/
- (BOOL)coreLocationStubAuthorizationStatus:(CLAuthorizationStatus)status;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
/**
 *  Stub CLLocationManager accuracyAuthorization
 *
 *  @param authorization accuracy authorization. The default value returned by `CLLocationManager.accuracyAuthorization` when enabling core location stubbing is `CLAccuracyAuthorizationFullAccuracy`
 *
 *  The `CLLocationManagerDelegate` method `locationManagerDidChangeAuthorization:` will be called on the `Main` thread.
 *
 *  @return `YES` on success
*/
- (BOOL)coreLocationStubAccuracyAuthorization:(CLAccuracyAuthorization)authorization API_AVAILABLE(ios(14));
#endif

/**
 *  Stub CLLocationManager locationServicesEnabled
 *
 *  @param flag location service status. The default value returned `+[CLLocationManager locationServicesEnabled]` by  when enabling core location stubbing is YES
 *
 *  @return `YES` on success
*/

- (BOOL)coreLocationStubLocationServicesEnabled:(BOOL)flag;

/**
 *  Tells all active CLLocationManager's delegates that the location manager has a new location data available.
 *
 *  @param locations an array of CLLocation objects containing the location data. This array should always contains at least one object representing the current location
 *
 *  The `CLLocationManagerDelegate` method `locationManager:didUpdateLocations:` will be called on the `Main` thread.
 *
 *  @return `YES` on success
*/
- (BOOL)coreLocationNotifyLocationUpdate:(nonnull NSArray<CLLocation *>*)locations;

/**
 *  Updates the current location of all active CLLocationManager's at the provided location.
 *
 *  @param location a CLLocation object containing the location data
 *
 *  @return `YES` on success
*/
- (BOOL)coreLocationStubManagerLocation:(nullable CLLocation *)location;

/**
 *  Tells all active CLLocationManager's delegates that the location manager was unable to retrieve a location value.
 *
 *  @param error the error object containing the reason the location or heading could not be retrieved.
 *
 *  The `CLLocationManagerDelegate` method `locationManager:didFailWithError:` will be called on the `Main` thread.
 *
 *  @return `YES` on success
*/
- (BOOL)coreLocationNotifyLocationError:(nonnull NSError *)error;

#pragma mark - XCUITest UNUserNotificationCenter extensions

/**
 *  Enable UNUserNotificationCenter stubbing
 *
 *  @param flag stubbing status
 *
 *  @return `YES` on success
*/
- (BOOL)notificationCenterStubEnabled:(BOOL)flag API_AVAILABLE(ios(10));

/**
 *  Stub UNUserNotificationCenter authorizationStatus
 *
 *  @param status notification center authorization status. The default value returned by `UNNotificationSettings.authorizationStatus` when enabling notication center stubbing is UNAuthorizationStatusAuthorized
 *
 *  @return `YES` on success
*/
- (BOOL)notificationCenterStubAuthorizationStatus:(UNAuthorizationStatus)status API_AVAILABLE(ios(10));

#pragma mark - XCUITest WKWebView stubbing

/**
 *  Toggle stubbing/throttling/monitoring in WKWebViews. You'll need to enable this before being able to interact with WKWebView's network requests.
 *
 *  Important: WKWebView do not publicly support for NSURLProtocol. To workaround this we're calling some private APIs that unfortunately have as a side effect that bodies of POST requests inside the WKWebViews are stripped away. Use with care!
 *
 *  @param flag stubbing status
 *
 *  @return `YES` on success
*/
- (BOOL)wkWebViewStubEnabled:(BOOL)flag;

@end
