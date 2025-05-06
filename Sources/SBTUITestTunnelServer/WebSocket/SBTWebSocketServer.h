// SBTWebSocketServer.h
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
@import Network;

NS_ASSUME_NONNULL_BEGIN

@class SBTWebSocketServer;

@protocol SBTWebSocketServerDelegate<NSObject>

- (void)webSocketServer:(SBTWebSocketServer *)sender didChangeState:(nw_connection_state_t)state;

@end

@interface SBTWebSocketServer : NSObject

/**
 *  WebSocketServer is a simple WebSocket server that listens for incoming connections and handles them.
 *
 *  @param port The port on which the server will listen for incoming connections
 */
- (instancetype)initWithPort:(NSInteger)port;

/**
 *  Starts listening and accepting connections.
 *
 *  @param error An error object that will be set if the server fails to start
 */
- (void)startWithError:(NSError **)error;

/**
 *  Sends the current stubbed response to all connected clients.
 *
 */
- (void)sendStubbedMessage;

@property (nonatomic, assign, readonly) NSInteger port;
@property (nonatomic, strong) NSData *stubbedMessage;
@property (nullable, nonatomic, weak) id<SBTWebSocketServerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
