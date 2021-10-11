//
//  _DTXIPCDistantObject.m
//  DetoxIPC
//
//  Created by Leo Natan (Wix) on 9/24/19.
//  Copyright © 2019 LeoNatan. All rights reserved.
//

#import "_DTXIPCDistantObject.h"
#import "DTXIPCConnection.h"
#import "DTXIPCConnection-Private.h"
#import "NSConnection.h"
#import "NSInvocation+DTXRemoteSerialization.h"
#import "_DTXIPCExportedObject.h"
#import "Swiftier.h"
@import ObjectiveC;
@import Darwin;

#define _ERROR_OR_ASSERT(condition, ...) if((condition) == NO) { if(_errorBlock != nil) { _errorBlock([NSError errorWithDomain:DTXIPCErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:__VA_ARGS__]}]); } else { NSAssert(condition, __VA_ARGS__); } }
#define ERROR_OR_ASSERT_V(condition, ...) _ERROR_OR_ASSERT(condition, __VA_ARGS__); if((condition) == NO) { return; }
#define ERROR_OR_ASSERT_NV(condition, ...) _ERROR_OR_ASSERT(condition, __VA_ARGS__); if((condition) == NO) { return nil; }

@implementation _DTXIPCDistantObject
{
	DTXIPCConnection* _connection;
	void (^_errorBlock)(NSError*);
	
	pthread_mutex_t _pendingMutex;
	NSMutableArray<_DTXIPCExportedObject*>* _pendingRemoteBlocks;
	
	dispatch_group_t _pendingDispatchGroup;
}

+ (instancetype)_distantObjectWithConnection:(DTXIPCConnection*)connection synchronous:(BOOL)synchronous errorBlock:(void(^)(NSError*))errorBlock
{
	_DTXIPCDistantObject* rv = [_DTXIPCDistantObject new];
	rv->_connection = connection;
	rv->_synchronous = synchronous;
	rv->_errorBlock = errorBlock;
	rv->_pendingRemoteBlocks = [NSMutableArray new];
	pthread_mutex_init(&(rv->_pendingMutex), NULL);
	
	NSString* className = [NSString stringWithFormat:@"_DTXIPCDistantObject_<%@>", NSStringFromProtocol(rv->_connection.remoteObjectInterface.protocol)];
	Class cls = objc_getClass(className.UTF8String);
	if(cls == nil)
	{
		cls = objc_allocateClassPair(_DTXIPCDistantObject.class, className.UTF8String, 0);
		class_addProtocol(cls, rv->_connection.remoteObjectInterface.protocol);
		objc_registerClassPair(cls);
	}
	object_setClass(rv, cls);
	
	return rv;
}

- (void)dealloc
{
	pthread_mutex_destroy(&_pendingMutex);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	NSMethodSignature* s = [super methodSignatureForSelector:aSelector];
	//A method call on the distant object proxy itself
	if(s) { return s; }
	
	ERROR_OR_ASSERT_NV(_connection.remoteObjectInterface != nil, @"No remote object interface specified.");
	//A method call to be forwarded to the distant object.
	return [_connection.remoteObjectInterface protocolMethodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
	if(_synchronous)
	{
		ERROR_OR_ASSERT_V(_pendingDispatchGroup == nil, @"You must not send messages from multiple threads to synchronous proxies.");
		
		_pendingDispatchGroup = dispatch_group_create();
	}
	
	NSDictionary* serialized = [invocation _dtx_serializedDictionaryForDistantObject:self];

	ERROR_OR_ASSERT_V(_connection.isValid, @"Connection %@ is invalid.", _connection);
	[_connection.otherConnection.rootProxy _invokeFromRemote:serialized];

	if(_synchronous)
	{
		BOOL somethingWentWrong = NO;
		BOOL didEndWaiting = NO;
		
		do {
			didEndWaiting = dispatch_group_wait(_pendingDispatchGroup, dispatch_walltime(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC))) == 0;
			
			if(didEndWaiting == NO)
			{
				@try {
					//Send a ping to check if the connection is still alive while waiting.
					[_connection.otherConnection.rootProxy _ping];
				} @catch (NSException *exception) {
					if(_errorBlock)
					{
						_errorBlock([NSError errorWithDomain:DTXIPCErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: exception.reason}]);
					}
					else
					{
						[exception raise];
					}
					somethingWentWrong = YES;
				}
			}
		} while(somethingWentWrong == NO && didEndWaiting == NO);

		if(didEndWaiting)
		{
			pthread_mutex_lock_deferred_unlock(&_pendingMutex);
			[_pendingRemoteBlocks enumerateObjectsUsingBlock:^(_DTXIPCExportedObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				[obj invoke];
			}];
			[_pendingRemoteBlocks removeAllObjects];
		}
		
		_pendingDispatchGroup = nil;
	}
}

- (void)_enterReplyBlock
{
	if(_synchronous == NO)
	{
		return;
	}
	
	dispatch_group_enter(_pendingDispatchGroup);
}

- (void)_leavelReplyBlock
{
	if(_synchronous == NO)
	{
		return;
	}
	
	dispatch_group_leave(_pendingDispatchGroup);
}

- (BOOL)_enqueueSynchronousExportedObjectInvocation:(_DTXIPCExportedObject*)object
{
	if(_synchronous == NO)
	{
		return NO;
	}
	
	pthread_mutex_lock_deferred_unlock(&_pendingMutex);
	[_pendingRemoteBlocks addObject:object];
	
	return YES;
}

@end
