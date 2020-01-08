// SBTUITunneledApplication.h
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
#endif

#if ENABLE_UITUNNEL

@import XCTest;

#import "SBTUITestTunnelClientProtocol.h"

/**
 *  An object that manages the test application's life-cycle. This object is used internally when ENABLE_UITUNNEL_SWIZZLING is set to 1.
 */
@interface SBTUITunneledApplication : XCUIApplication <SBTUITestTunnelClientProtocol>

/**
 *  Launch application synchronously waiting for the tunnel server connection to be established.
 *
 *  @param options List of options to be passed on launch.
 *  Valid options:
 *  SBTUITunneledApplicationLaunchOptionResetFilesystem: delete app's filesystem sandbox
 *  SBTUITunneledApplicationLaunchOptionDisableUITextFieldAutocomplete disables UITextField's autocomplete functionality which can lead to unexpected results when typing text.
 *
 *  @param startupBlock Block that is executed before connection is estabilished.
 *  Useful to inject startup condition (user settings, preferences).
 *  Note: commands sent in the completionBlock will return nil
 */
- (void)launchTunnelWithOptions:(nonnull NSArray<NSString *> *)options startupBlock:(nullable void (^)(void))startupBlock;

@end

#endif
