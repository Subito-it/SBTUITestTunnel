//
//  DTXIPCConnection.h
//  DetoxIPC
//
//  Created by Leo Natan (Wix) on 9/24/19.
//  Copyright © 2019 LeoNatan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXIPCBase.h"

NS_ASSUME_NONNULL_BEGIN

/// This object holds all information about the interface of an exported or imported object. This includes: what messages are allowed, what kinds of objects are allowed as arguments and what the signature of any block arguments are.
@interface DTXIPCInterface : NSObject

/// Factory method to get an DTXIPCInterface instance for a given protocol.
+ (instancetype)interfaceWithProtocol:(Protocol *)protocol;

/// The protocol configured for the interface.
@property (nonatomic, readonly) Protocol* protocol;
/// The method signatures from the configured protocol.
@property (nonatomic, strong, readonly) NSArray<NSMethodSignature*>* methodSignatures;
/// Returns a method signature from the protocol, for the given selector.
- (NSMethodSignature*)protocolMethodSignatureForSelector:(SEL)aSelector;

@end

// This object is the main configuration mechanism for the communication between two processes. Each DTXIPCConnection instance has a private thread. This thread is used when sending messages to objects and blocks.
@interface DTXIPCConnection : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


/// Initialize a DTXIPCConnection that will register and serve the specified service name.
/// @param serviceName The service name to register
- (instancetype)initWithServiceName:(NSString*)serviceName;

/// Initialize a DTXIPCConnection that will connect to specified already-registered service name.
/// @param serviceName The service name to connect to
- (instancetype)initWithRegisteredServiceName:(NSString*)serviceName DTXIPC_DEPRECATED_API("Use initWithServiceName:");

/// The registered service name.
@property (nullable, readonly, copy, nonatomic) NSString *serviceName;

/// The invalidation handler will be called if the connection can not be formed or the connection has terminated and may not be re-established. The invalidation handler will also be called if a connection is invalidated from the remote side. The handler will be invoked on the same queue as replies and other handlers, but there is no guarantee of ordering between those callbacks and this one.
///
/// You may not send messages over the connection from within an invalidation handler block.
///
/// The invalidationHandler property is cleared after the connection becomes invalid. This is to mitigate the impact of a retain cycle created by referencing the DTXIPCConnection instance inside this block.
@property(copy) void (^invalidationHandler)(void);

/// The interface that describes messages that are allowed to be received by the exported object on this connection. This value is required if a exported object is set.
@property(retain, nonatomic) DTXIPCInterface *exportedInterface;
/// Set an exported object for the connection. Messages sent to the remoteObjectProxy from the other side of the connection will be dispatched to this object. Messages delivered to exported objects are serialized and sent on a non-main thread. The receiver is responsible for handling the messages on a different thread if it is required.
@property(retain, nonatomic) id exportedObject;

/// The interface that describes messages that are allowed to be received by object that has been "imported" to this connection (exported from the other side). This value is required if messages are sent over this connection.
@property(retain, nonatomic) DTXIPCInterface *remoteObjectInterface;

/// Returns a proxy object with no error handling block. Messages sent to the proxy object will be sent over the wire to the other side of the connection. All messages must be 'oneway void' return type. Control may be returned to the caller before the message is sent.
@property(readonly, retain, nonatomic) id remoteObjectProxy;
/// Returns a proxy object which will invoke the error handling block if an error occurs on the connection. Messages sent to the proxy object will be sent over the wire to the other side of the connection. All messages must be 'oneway void' return type. Control may be returned to the caller before the message is sent.
- (id)remoteObjectProxyWithErrorHandler:(void (^)(NSError *error))handler;
/// Make a synchronous IPC call instead of the default async behavior. The error handler block and block arguments will be invoked on the calling thread before the message to the proxy returns, instead of on the queue for the connection.
///
/// Synchronous calls will block until the remote has released all argument blocks.
///
/// You must not send messages from multiple threads to synchronous proxies.
- (id)synchronousRemoteObjectProxyWithErrorHandler:(void (^)(NSError *error))handler;

/// All connections start suspended. You must resume them before they will start processing received messages or sending messages through the remoteObjectProxy.
- (void)resume;

/// Invalidate the connection. All outstanding error handling blocks will be called on the message handling queue. The connection must be invalidated before it is deallocated. After a connection is invalidated, no more messages may be sent or received.
- (void)invalidate;

- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END
