// CLLocationManager+Swizzles.m
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

#if !DISABLE_UITUNNEL_SWIZZLING

@import SBTUITestTunnelCommon;
@import CoreLocation;

#import "CLLocationManager+Swizzles.h"

#import <os/lock.h>

// Guards every static below. Critical sections never call out to delegates or app code.
static os_unfair_lock sStateLock = OS_UNFAIR_LOCK_INIT;
static NSMapTable<CLLocationManager *, id<CLLocationManagerDelegate>> *_instanceHashTable;
static NSMapTable<CLLocationManager *, id<CLLocationManagerDelegate>> *_delegatesHashTable;
static CLAuthorizationStatus _authorizationStatus = kCLAuthorizationStatusAuthorizedAlways;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
static CLAccuracyAuthorization _accuracyAuthorization = CLAccuracyAuthorizationFullAccuracy;
#endif
static CLLocation *_currentLocation;
static BOOL _locationServicesEnabled = YES;

static CLAuthorizationStatus SBTStubbedAuthorizationStatus(void)
{
    os_unfair_lock_lock(&sStateLock);
    CLAuthorizationStatus status = _authorizationStatus;
    os_unfair_lock_unlock(&sStateLock);

    return status;
}

@implementation CLLocationManager (Swizzles)

static char const * const swz_creationThreadKey = "swz_creationThreadKey";

- (void)setSwz_creationThread:(NSThread *)thread {
    objc_setAssociatedObject(self, swz_creationThreadKey, thread, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSThread *)swz_creationThread {
    return objc_getAssociatedObject(self, swz_creationThreadKey);
}

- (instancetype)init_swz {
    self = [self init_swz];
    if (self) {
        self.swz_creationThread = [NSThread currentThread];
    }
    return self;
}

- (void)sbt_markActive
{
    // Released after unlocking, in case this is the last reference and the delegate's dealloc reenters
    id<CLLocationManagerDelegate> delegate NS_VALID_UNTIL_END_OF_SCOPE;

    os_unfair_lock_lock(&sStateLock);
    delegate = [_delegatesHashTable objectForKey:self];
    [_instanceHashTable setObject:delegate forKey:self];
    os_unfair_lock_unlock(&sStateLock);
}

- (void)sbt_markInactive
{
    os_unfair_lock_lock(&sStateLock);
    [_instanceHashTable removeObjectForKey:self];
    os_unfair_lock_unlock(&sStateLock);
}

- (void)swz_startMonitoring
{
    [self sbt_markActive];
}

- (void)swz_startUpdatingLocation
{
    [self sbt_markActive];
}

- (void)swz_startUpdatingHeading
{
    [self sbt_markActive];
}

- (void)swz_requestLocation
{
    [self sbt_markActive];
}

- (void)swz_requestAlwaysAuthorization
{
    [self sbt_markActive];
}

- (void)swz_requestWhenInUseAuthorization
{
    [self sbt_markActive];
}

- (void)swz_stopMonitoring
{
    [self sbt_markInactive];
}

- (void)swz_stopUpdatingLocation
{
    [self sbt_markInactive];
}

- (void)swz_stopUpdatingHeading
{
    [self sbt_markInactive];
}

+ (CLAuthorizationStatus)swz_authorizationStatus
{
    return SBTStubbedAuthorizationStatus();
}

- (CLAuthorizationStatus)swz_authorizationStatus
{
    return SBTStubbedAuthorizationStatus();
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
- (CLAccuracyAuthorization)swz_accuracyAuthorization API_AVAILABLE(ios(14.0))
{
    os_unfair_lock_lock(&sStateLock);
    CLAccuracyAuthorization accuracy = _accuracyAuthorization;
    os_unfair_lock_unlock(&sStateLock);

    return accuracy;
}
#endif

+ (BOOL)swz_locationServicesEnabled
{
    os_unfair_lock_lock(&sStateLock);
    BOOL enabled = _locationServicesEnabled;
    os_unfair_lock_unlock(&sStateLock);

    return enabled;
}

- (void)swz_setDelegate:(id<CLLocationManagerDelegate>)delegate
{
    os_unfair_lock_lock(&sStateLock);
    if (delegate == nil) {
        // NSMapTable ignores setObject:nil, which would leave the previous delegate registered
        [_delegatesHashTable removeObjectForKey:self];
        [_instanceHashTable removeObjectForKey:self];
    } else {
        [_delegatesHashTable setObject:delegate forKey:self];
        [_instanceHashTable setObject:delegate forKey:self];
    }
    os_unfair_lock_unlock(&sStateLock);

    if (delegate == nil) {
        return;
    }

    // Core Location always calls locationManagerDidChangeAuthorization:
    // ... when your app creates an instance of CLLocationManager,
    // whether your app runs in the foreground or in the background.
    [self sbt_sendAuthorizationStatusToDelegate];
}

- (void)sbt_sendAuthorizationStatusToDelegate
{
    [self sbt_performOnCreationThread:^{
        // Looked up on delivery, so a delegate cleared or replaced in the meantime isn't notified
        id<CLLocationManagerDelegate> delegate = [self sbt_registeredDelegate];

        if ([delegate respondsToSelector:@selector(locationManager:didChangeAuthorizationStatus:)]) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            [delegate locationManager:self didChangeAuthorizationStatus:self.authorizationStatus];
#pragma GCC diagnostic pop
        }

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
        if (@available(iOS 14.0, *)) {
            // The legacy callback may have cleared or replaced the delegate
            delegate = [self sbt_registeredDelegate];

            if ([delegate respondsToSelector:@selector(locationManagerDidChangeAuthorization:)]) {
                [delegate locationManagerDidChangeAuthorization:self];
            }
        }
#endif
    }];
}

- (void)sbt_performOnCreationThread:(dispatch_block_t)block
{
    NSThread *thread = self.swz_creationThread ?: NSThread.mainThread;

    [self performSelector:@selector(sbt_executeBlock:)
                 onThread:thread
               withObject:[block copy]
            waitUntilDone:NO];
}

- (void)sbt_executeBlock:(dispatch_block_t)block
{
    @autoreleasepool {
        block();
    }
}

+ (NSArray<CLLocationManager *> *)sbt_activeManagersSnapshot
{
    // Strong references are taken under the lock and released after it, keeping managers alive while events are queued
    NSArray<CLLocationManager *> *managers NS_VALID_UNTIL_END_OF_SCOPE;

    os_unfair_lock_lock(&sStateLock);
    managers = _instanceHashTable.keyEnumerator.allObjects;
    os_unfair_lock_unlock(&sStateLock);

    return managers ?: @[];
}

- (id<CLLocationManagerDelegate>)stubbedDelegate
{
    id<CLLocationManagerDelegate> delegate NS_VALID_UNTIL_END_OF_SCOPE;

    os_unfair_lock_lock(&sStateLock);
    delegate = [_instanceHashTable objectForKey:self];
    os_unfair_lock_unlock(&sStateLock);

    return delegate;
}

- (id<CLLocationManagerDelegate>)sbt_registeredDelegate
{
    id<CLLocationManagerDelegate> delegate NS_VALID_UNTIL_END_OF_SCOPE;

    os_unfair_lock_lock(&sStateLock);
    delegate = [_delegatesHashTable objectForKey:self];
    os_unfair_lock_unlock(&sStateLock);

    return delegate;
}

+ (void)setStubbedAuthorizationStatus:(CLAuthorizationStatus)authorizationStatus
{
    os_unfair_lock_lock(&sStateLock);
    _authorizationStatus = authorizationStatus;
    os_unfair_lock_unlock(&sStateLock);
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
+ (void)setStubbedAccuracyAuthorization:(CLAccuracyAuthorization)accuracyAuthorization
{
    os_unfair_lock_lock(&sStateLock);
    _accuracyAuthorization = accuracyAuthorization;
    os_unfair_lock_unlock(&sStateLock);
}
#endif

+ (void)setStubbedCurrentLocation:(CLLocation *)location
{
    CLLocation *previousLocation NS_VALID_UNTIL_END_OF_SCOPE;

    os_unfair_lock_lock(&sStateLock);
    previousLocation = _currentLocation;
    _currentLocation = location;
    os_unfair_lock_unlock(&sStateLock);
}

+ (void)setStubbedLocationServicesEnabled:(BOOL)enabled
{
    os_unfair_lock_lock(&sStateLock);
    _locationServicesEnabled = enabled;
    os_unfair_lock_unlock(&sStateLock);
}

- (CLLocation *)location
{
    CLLocation *location NS_VALID_UNTIL_END_OF_SCOPE;

    os_unfair_lock_lock(&sStateLock);
    location = _currentLocation;
    os_unfair_lock_unlock(&sStateLock);

    return location;
}

+ (void)loadSwizzles
{
    os_unfair_lock_lock(&sStateLock);
    if (_instanceHashTable == nil) {
        _instanceHashTable = NSMapTable.weakToWeakObjectsMapTable;
        _delegatesHashTable = NSMapTable.weakToWeakObjectsMapTable;
    }
    os_unfair_lock_unlock(&sStateLock);
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SBTTestTunnelInstanceSwizzle(self.class, @selector(init), @selector(init_swz));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(startMonitoring), @selector(swz_startMonitoring));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(startUpdatingLocation), @selector(swz_startUpdatingLocation));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(startUpdatingHeading), @selector(swz_startUpdatingHeading));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(stopMonitoring), @selector(swz_stopMonitoring));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(stopUpdatingLocation), @selector(swz_stopUpdatingLocation));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(stopUpdatingHeading), @selector(swz_stopUpdatingHeading));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(requestLocation), @selector(swz_requestLocation));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(requestAlwaysAuthorization), @selector(swz_requestAlwaysAuthorization));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(requestWhenInUseAuthorization), @selector(swz_requestWhenInUseAuthorization));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(setDelegate:), @selector(swz_setDelegate:));
        
        SBTTestTunnelInstanceSwizzle(self.class, @selector(authorizationStatus), @selector(swz_authorizationStatus));            
        #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
            SBTTestTunnelInstanceSwizzle(self.class, @selector(accuracyAuthorization), @selector(swz_accuracyAuthorization));
        #endif
            
        SBTTestTunnelClassSwizzle(self, @selector(authorizationStatus), @selector(swz_authorizationStatus));
        SBTTestTunnelClassSwizzle(self, @selector(locationServicesEnabled), @selector(swz_locationServicesEnabled));
    });
}

+ (void)removeSwizzles
{
    os_unfair_lock_lock(&sStateLock);
    [_instanceHashTable removeAllObjects];
    [_delegatesHashTable removeAllObjects];
    os_unfair_lock_unlock(&sStateLock);
    
    // Repeat swizzle to restore default implementation
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SBTTestTunnelInstanceSwizzle(self.class, @selector(init), @selector(init_swz));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(startMonitoring), @selector(swz_startMonitoring));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(startUpdatingLocation), @selector(swz_startUpdatingLocation));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(startUpdatingHeading), @selector(swz_startUpdatingHeading));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(stopMonitoring), @selector(swz_stopMonitoring));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(stopUpdatingLocation), @selector(swz_stopUpdatingLocation));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(stopUpdatingHeading), @selector(swz_stopUpdatingHeading));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(requestLocation), @selector(swz_requestLocation));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(requestAlwaysAuthorization), @selector(swz_requestAlwaysAuthorization));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(requestWhenInUseAuthorization), @selector(swz_requestWhenInUseAuthorization));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(setDelegate:), @selector(swz_setDelegate:));
        
        SBTTestTunnelInstanceSwizzle(self.class, @selector(authorizationStatus), @selector(swz_authorizationStatus));
        #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
            SBTTestTunnelInstanceSwizzle(self.class, @selector(accuracyAuthorization), @selector(swz_accuracyAuthorization));
        #endif

        SBTTestTunnelClassSwizzle(self, @selector(authorizationStatus), @selector(swz_authorizationStatus));
        SBTTestTunnelClassSwizzle(self, @selector(locationServicesEnabled), @selector(swz_locationServicesEnabled));
    });
}

@end

#endif
