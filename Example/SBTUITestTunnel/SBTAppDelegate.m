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
@import SBTUITestTunnelServer;

@implementation SBTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [SBTUITestTunnelServer takeOff];

    if ([[NSProcessInfo processInfo].arguments containsObject:@"wait_for_startup_test"]) {
        [SBTUITestTunnelServer takeOffCompleted:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SBTUITestTunnelServer takeOffCompleted:YES];
        });
    } else {
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

        [SBTUITestTunnelServer takeOffCompleted:YES];
    }
    
    return YES;
}

@end
