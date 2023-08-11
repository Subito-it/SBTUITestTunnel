// SBTUITestTunnelClient.h
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

@import SBTUITestTunnelCommon;

#import "SBTUITestTunnelClientProtocol.h"

// These imports are required for SPM as this file will be the umbrella header
#import "XCTestCase+AppExtension.h"
#import "SBTUITunneledApplication.h"

typedef enum: NSUInteger {
    SBTUITestTunnelErrorLaunchFailed = 101,
    SBTUITestTunnelErrorConnectionToApplicationFailed = 201,
    SBTUITestTunnelErrorOtherFailure = 301
} SBTUITestTunnelError;

@class SBTUITestTunnelClient;
@class XCUIApplication;

/**
 *  Create an instance of SBTUITestTunnelClientDelegate.
 *
 *  The methods adopted by the object you use to manage the application life-cycle usually an instance of XCUIApplication.
 */
@protocol SBTUITestTunnelClientDelegate <NSObject>

/**
 Informs the delegate that it should launch the XCUIApplication under-test before the tunnel is established.
 It's required that you avoid launching until the delegate is called.

 @param sender An instance of the object sending the message.
 @param url URL the app was launched with.
 */
- (void)tunnelClientIsReadyToLaunch:(nonnull SBTUITestTunnelClient *)sender url:(nullable NSURL *)url;
@optional

/**
 Informs the delegate than the tunnel did shutdown.

 @param sender An instance of the object sending the message.
 @param error If shutdown was due to an error will be non-nil, if shutdown was normal and expected then error will be nil.
 */
- (void)tunnelClient:(nonnull SBTUITestTunnelClient *)sender didShutdownWithError:(NSError * _Nullable)error;
@end


/**
 *  An object that establises a tunnel between the test runner and application being tested for the purposes of stubbing network calls, interacting with user defaults and more.
 *
 *  See SBTUITestTunnelClientProtocol.h for full API documentation.
 *
 *  The following options can be set as `XCUIApplication.launchArguments` for additional behaviours:
 *  SBTUITunneledApplicationLaunchOptionResetFilesystem: delete app's filesystem sandbox
 *  SBTUITunneledApplicationLaunchOptionDisableUITextFieldAutocomplete disables UITextField's autocomplete functionality which can lead to unexpected results when typing text.
 */
@interface SBTUITestTunnelClient : NSObject <SBTUITestTunnelClientProtocol>

/**
 *  The object that acts as the delegate of the tunneled application.
 *
 *  The delegate must adopt the SBTUITunneledApplicationDelegate protocol. The delegate is not retained.
 */
@property (nonatomic, weak) id<SBTUITestTunnelClientDelegate> _Nullable delegate;

/**
 *  Create an instance of SBTUITestTunnelClient passing in an XCUIApplication to use.
 *
 *  @param application The instance of XCUIApplication.
 */
- (nonnull instancetype)initWithApplication:(nonnull XCUIApplication *)application;

@end
