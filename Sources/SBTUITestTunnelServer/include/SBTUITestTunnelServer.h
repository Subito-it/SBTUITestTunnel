// SBTUITestTunnelServer.h
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

@import Foundation;

// These imports are required for SPM as this file will be the umbrella header
#import "UIViewController+SBTUITestTunnel.h"
#import "UIScrollView+SBTUITestTunnel.h"
#import "SBTAnyViewControllerPreviewing.h"

@interface SBTUITestTunnelServer : NSObject

/**
 *  Start the tunnel server
 *
 *  @return `YES` on success
 */
+ (BOOL)takeOff;

/**
 *  Register a custom command. It is your responsibility to unregister the custom command when it is no longer needed
 *
 *  @param commandName that will match [SBTUITestTunnelClient performCustomCommandNamed:object:]
 *  @param block the block of code that will be executed once the command is received
 */
+ (void)registerCustomCommandNamed:(nonnull NSString *)commandName block:(nonnull NSObject *_Nullable(^)(NSObject * _Nullable object))block;

/**
 *  Unregister a custom command.
 *
 *  @param commandName the name of the custom command that was registered using [SBTUITestTunnelServer registerCustomCommandNamed:block:]
 */
+ (void)unregisterCommandNamed:(nonnull NSString *)commandName;

@end
