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
 */
- (void)tunnelClientIsReadyToLaunch:(nonnull SBTUITestTunnelClient *)sender;
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

/**
 *  Launch a WebSocket server in the application with the specified identifier.
 *
 *  @param identifier A unique identifier for the WebSocket server.
 *  @return The port number that the WebSocket server is running on.
 */
- (NSInteger)launchWebSocketWithIdentifier:(nonnull NSString *)identifier NS_SWIFT_NAME(launchWebSocket(identifier:));

/**
 *  Stub responses for a WebSocket connection.
 *
 *  @param responseData The data to be returned when the client receives a message.
 *  @param identifier The identifier of the WebSocket connection.
 *  @return `YES` on success.
 */
- (BOOL)stubWebSocketReceiveMessage:(nonnull NSData *)responseData withIdentifier:(nonnull NSString *)identifier NS_SWIFT_NAME(stubWebSocketReceiveMessage(_:identifier:));

/**
 *  Flush received messages from a WebSocket connection.
 *
 *  @param identifier The identifier of the WebSocket connection.
 *  @return An array of NSData containing the received messages, or nil on failure.
 */
- (nonnull NSArray<NSData *> *)flushWebSocketMessagesWithIdentifier:(nonnull NSString *)identifier NS_SWIFT_NAME(flushWebSocketMessages(identifier:));

/**
 *  Synchronously send the currently stubbed message to the WebSocket server.
 *
 *  @param message The message data to send to the WebSocket server.
 *  @param identifier The identifier of the WebSocket connection.
 *  @return `YES` on success.
 */
- (BOOL)sendWebSocketMessage:(nonnull NSData *)message withIdentifier:(nonnull NSString *)identifier NS_SWIFT_NAME(sendWebSocket(message:identifier:));

/**
 *  Get the current WebSocket connection state.
 *
 *  @param identifier The identifier of the WebSocket connection.
 *  @return `YES` if connected, `NO` otherwise.
 */
- (BOOL)webSocketConnectionStateWithIdentifier:(nonnull NSString *)identifier NS_SWIFT_NAME(webSocketConnectionState(identifier:));

@end
