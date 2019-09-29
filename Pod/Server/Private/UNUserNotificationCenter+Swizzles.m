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

#if DEBUG
    #ifndef ENABLE_UITUNNEL
        #define ENABLE_UITUNNEL 1
    #endif

    #ifndef ENABLE_UITUNNEL_SWIZZLING
        #define ENABLE_UITUNNEL_SWIZZLING 1
    #endif
#endif

#if ENABLE_UITUNNEL && ENABLE_UITUNNEL_SWIZZLING

#import "UNUserNotificationCenter+Swizzles.h"
#import <UserNotifications/UNNotificationSettings.h>
#import <SBTUITestTunnelCommon/SBTSwizzleHelpers.h>

static NSString *_autorizationStatus;

@implementation UNUserNotificationCenter (Swizzles)

- (void)swz_requestAuthorizationWithOptions:(UNAuthorizationOptions)options completionHandler:(void (^)(BOOL, NSError *))completionHandler
{
    NSString *defaultStatus = [@(UNAuthorizationStatusAuthorized) stringValue];
    NSInteger status = (_autorizationStatus ?: defaultStatus).intValue;

    if (completionHandler != nil) {
        completionHandler(status == UNAuthorizationStatusAuthorized, nil);
    }
}

- (void)swz_getNotificationSettingsWithCompletionHandler:(void (^)(UNNotificationSettings *))completionHandler
{
    NSString *defaultStatus = [@(UNAuthorizationStatusAuthorized) stringValue];
    NSInteger status = (_autorizationStatus.length > 0 ? _autorizationStatus : defaultStatus).intValue;

    SEL sel = NSSelectorFromString(@"emptySettings");
    UNNotificationSettings *settings = [UNNotificationSettings performSelector:sel];

    NSNumber *defaultNotificationSetting = @(UNNotificationSettingEnabled);
    
    [settings setValue:@(status) forKey:@"authorizationStatus"];
    [settings setValue:defaultNotificationSetting forKey:@"soundSetting"];
    [settings setValue:defaultNotificationSetting forKey:@"badgeSetting"];
    [settings setValue:defaultNotificationSetting forKey:@"alertSetting"];
    [settings setValue:defaultNotificationSetting forKey:@"notificationCenterSetting"];
    [settings setValue:defaultNotificationSetting forKey:@"lockScreenSetting"];
    [settings setValue:defaultNotificationSetting forKey:@"carPlaySetting"];
    [settings setValue:defaultNotificationSetting forKey:@"alertSetting"];
    [settings setValue:defaultNotificationSetting forKey:@"showPreviewsSetting"];
    [settings setValue:defaultNotificationSetting forKey:@"announcementSetting"];
    [settings setValue:defaultNotificationSetting forKey:@"groupingSetting"];
    
    if (completionHandler != nil) {
        completionHandler(settings);
    }
}

+ (void)loadSwizzlesWithAuthorizationStatus:(NSString *)autorizationStatus
{
    _autorizationStatus = autorizationStatus;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SBTTestTunnelInstanceSwizzle(self.class, @selector(requestAuthorizationWithOptions:completionHandler:), @selector(swz_requestAuthorizationWithOptions:completionHandler:));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(getNotificationSettingsWithCompletionHandler:), @selector(swz_getNotificationSettingsWithCompletionHandler:));
    });
}

+ (void)removeSwizzles
{    
    // Repeat swizzle to restore default implementation
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SBTTestTunnelInstanceSwizzle(self.class, @selector(requestAuthorizationWithOptions:completionHandler:), @selector(swz_requestAuthorizationWithOptions:completionHandler:));
        SBTTestTunnelInstanceSwizzle(self.class, @selector(getNotificationSettingsWithCompletionHandler:), @selector(swz_getNotificationSettingsWithCompletionHandler:));
    });
}

@end

#endif
