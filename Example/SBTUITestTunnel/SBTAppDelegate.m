// SBTAppDelegate.m
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

#import "SBTAppDelegate.h"

@import SBTUITestTunnelCommon;
@import SBTUITestTunnelServer;
@import CoreLocation;

@implementation SBTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [SBTUITestTunnelServer registerCustomCommandNamed:@"myCustomCommandReturnNil" block:^NSObject *(NSObject *object) {
        [[NSUserDefaults standardUserDefaults] setObject:object forKey:@"custom_command_test"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        return nil;
    }];
    [SBTUITestTunnelServer registerCustomCommandNamed:@"myCustomCommandReturn123" block:^NSObject *(NSObject *object) {
        [[NSUserDefaults standardUserDefaults] setObject:object forKey:@"custom_command_test"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        return @"123";
    }];
    [SBTUITestTunnelServer registerCustomCommandNamed:@"isSBTProxyURLProtocolRegistered" block:^NSObject *(NSObject *object) {
        [SBTProxyURLProtocol stubRequestsMatching:[[SBTRequestMatch alloc] initWithURL:@".*" query:nil method:nil body:nil requestHeaders:nil responseHeaders:nil] stubResponse:[[SBTStubResponse alloc] initWithResponse:@"" headers:nil contentType:nil returnCode:0 responseTime:0 activeIterations:0]];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.subito.it"]];
        Class klass = [NSURLProtocol performSelector:NSSelectorFromString(@"_protocolClassForRequest:") withObject:request];
        
        return @([NSStringFromClass(klass) isEqualToString:@"SBTProxyURLProtocol"]);
    }];
    
    #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
    if (@available(iOS 14.0, *)) {
        [SBTUITestTunnelServer registerCustomCommandNamed:@"myCustomCommandReturnCLAccuracyAuth" block:^NSObject *(NSObject *object) {
            CLLocationManager *manager = [CLLocationManager new];
            return [@(manager.accuracyAuthorization) stringValue];
        }];
        [SBTUITestTunnelServer registerCustomCommandNamed:@"myCustomCommandReturnCLAuthStatus" block:^NSObject *(NSObject *object) {
            return [@([CLLocationManager authorizationStatus]) stringValue];
        }];

        [SBTUITestTunnelServer registerCustomCommandNamed:@"myCustomCommandReturnUNAuthRequest" block:^NSObject *(NSObject *object) {
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            __block BOOL authGranted;
            [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions: UNAuthorizationOptionNone completionHandler:^(BOOL granted, NSError * _Nullable error) {
                authGranted = granted;
                dispatch_semaphore_signal(sema);
            }];

            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            return [@(authGranted) stringValue];
        }];

        [SBTUITestTunnelServer registerCustomCommandNamed:@"myCustomCommandReturnUNAuthStatus" block:^NSObject *(NSObject *object) {
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);

            __block UNNotificationSettings *notificationSettings;
            [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
                notificationSettings = settings;
                dispatch_semaphore_signal(sema);
            }];

            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            return [@(notificationSettings.authorizationStatus) stringValue];
        }];
    }
    #endif

    BOOL didTakeOff = [SBTUITestTunnelServer takeOff];
    NSLog(@"Tunnel established: %d", didTakeOff);
    
    return YES;
}

@end
