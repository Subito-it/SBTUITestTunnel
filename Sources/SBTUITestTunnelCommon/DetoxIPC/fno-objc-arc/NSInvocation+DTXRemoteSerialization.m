//
//  NSInvocation+DTXRemoteSerialization.m
//  DetoxIPC
//
//  Created by Leo Natan (Wix) on 9/25/19.
//  Copyright © 2019 LeoNatan. All rights reserved.
//

/***
*    ██╗    ██╗ █████╗ ██████╗ ███╗   ██╗██╗███╗   ██╗ ██████╗
*    ██║    ██║██╔══██╗██╔══██╗████╗  ██║██║████╗  ██║██╔════╝
*    ██║ █╗ ██║███████║██████╔╝██╔██╗ ██║██║██╔██╗ ██║██║  ███╗
*    ██║███╗██║██╔══██║██╔══██╗██║╚██╗██║██║██║╚██╗██║██║   ██║
*    ╚███╔███╔╝██║  ██║██║  ██║██║ ╚████║██║██║ ╚████║╚██████╔╝
*     ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚═════╝
*
*
* WARNING: This file compiles with ARC disabled! Take extra care when modifying or adding functionality.
*/

#if DEBUG
    #ifndef ENABLE_UITUNNEL
        #define ENABLE_UITUNNEL 1
    #endif
#endif

#if ENABLE_UITUNNEL

#import "NSInvocation+DTXRemoteSerialization.h"
#import "_DTXIPCRemoteBlockRegistry.h"
#import "DTXIPCConnection-Private.h"
#import "NSConnection.h"
#import "_DTXIPCDistantObject.h"
@import UIKit;
@import ObjectiveC;

void* _DTXRemoteBlockIdentifierKey = &_DTXRemoteBlockIdentifierKey;
static void* _DTXCleanupIdentifierKey = &_DTXCleanupIdentifierKey;

extern const char * _Block_signature(id aBlock);
extern id __NSMakeSpecialForwardingCaptureBlock(const char *signature, void (^handler)(NSInvocation *inv));

@interface _DTXCleanUpHandler : NSObject @end
@implementation _DTXCleanUpHandler
{
	dispatch_block_t _cleanupBlock;
}

+ (instancetype)cleanUpHandlerWithBlock:(dispatch_block_t)block
{
	NSParameterAssert(block != nil);
	_DTXCleanUpHandler* rv = [_DTXCleanUpHandler new];
	rv->_cleanupBlock = _Block_copy(block);
	return [rv autorelease];
}

- (void)dealloc
{
	_cleanupBlock();
	
	_Block_release(_cleanupBlock);
	
	[super dealloc];
}

@end

@implementation NSInvocation (DTXRemoteSerialization)

//Returns autoreleased encoded object
static id _encodeObject(id object, _DTXIPCDistantObject* distantObject)
{
	if(object == nil)
	{
		return [NSNull null];
	}
	
	NSMutableDictionary* encodedObj = [NSMutableDictionary dictionary];
	
	if([object isKindOfClass:NSClassFromString(@"NSBlock")])
	{
		const char* blockSig = _Block_signature(object);
		
		const char* returnType = [NSMethodSignature signatureWithObjCTypes:blockSig].methodReturnType;
		if(*returnType != 'v')
		{
			[NSException raise:NSInvalidArgumentException format:@"Block arguments must have 'void' return type."];
		}
	
		encodedObj[@"type"] = @"block";
		encodedObj[@"signature"] = @(blockSig);
		//Register the original block in the registry.
		encodedObj[@"remoteIdentifier"] = [_DTXIPCRemoteBlockRegistry registerRemoteBlock:object distantObject:distantObject];
	}
	else
	{
		if(![object conformsToProtocol:@protocol(NSSecureCoding)])
		{
			[NSException raise:NSInvalidArgumentException format:@"%@ does not conform to NSSecureCoding", object];
		}
		
		if(class_isMetaClass(object_getClass(object)))
		{
			[NSException raise:NSInvalidArgumentException format:@"Class objects may not be encoded"];
		}
		
		Class cls = [object classForCoder];
		if (cls == NULL)
		{
			[NSException raise:NSInvalidArgumentException format:@"-classForCoder returned nil for %@", object];
		}
		
		encodedObj[@"type"] = @"object";
		encodedObj[@"className"] = NSStringFromClass(cls);
		encodedObj[@"data"] = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:NO error:NULL];
	}
	
	return encodedObj;
}

static void _encodeInvocation(NSInvocation* self, NSMutableDictionary* serialized, NSUInteger firstArg, _DTXIPCDistantObject* distantObject)
{
	NSMethodSignature* signature = self.methodSignature;
	NSMutableArray* arguments = [NSMutableArray arrayWithCapacity:signature.numberOfArguments];
	
	for(NSUInteger i = 0; i < firstArg; i++)
	{
		[arguments addObject:[NSNull null]];
	}
	
	for(NSUInteger i = firstArg; i < signature.numberOfArguments; i++)
	{
		const char* type = [signature getArgumentTypeAtIndex:i];
	
		switch (*type)
		{
			// double
			case 'd':
			{
				double value;
				[self getArgument:&value atIndex:i];
				
				[arguments addObject:_encodeObject(@(value), distantObject)];
				break;
			}
				
			// float
			case 'f':
			{
				float value;
				[self getArgument:&value atIndex:i];
				
				[arguments addObject:_encodeObject(@(value), distantObject)];
				break;
			}
				
			// int
			case 'i':
			{
				int value;
				[self getArgument:&value atIndex:i];
				
				[arguments addObject:_encodeObject(@(value), distantObject)];
				break;
			}
				
			// unsigned
			case 'I':
			{
				unsigned value;
				[self getArgument:&value atIndex:i];
				
				[arguments addObject:_encodeObject(@(value), distantObject)];
				break;
			}
				
			// char
			case 'c':
			{
				char value;
				[self getArgument:&value atIndex:i];
				
				[arguments addObject:_encodeObject(@(value), distantObject)];
				break;
			}
				
			// bool
			case 'B':
			{
				BOOL value;
				[self getArgument:&value atIndex:i];
				
				[arguments addObject:_encodeObject(@(value), distantObject)];
				break;
			}
				
			// long
			case 'q':
			{
				long value;
				[self getArgument:&value atIndex:i];
				
				[arguments addObject:_encodeObject(@(value), distantObject)];
				break;
			}
				
			// unsigned long
			case 'Q':
			{
				unsigned long value;
				[self getArgument:&value atIndex:i];
				
				[arguments addObject:_encodeObject(@(value), distantObject)];
				break;
			}
				
			// Objective-C object
			case '@':
			{
				id value;
				[self getArgument:&value atIndex:i];
				
				[arguments addObject:_encodeObject(value, distantObject)];
				break;
			}
				
			// struct
			case '{':
				if(!strcmp(type, @encode(NSRange)))
				{
					NSRange value;
					[self getArgument:&value atIndex:i];
					
					[arguments addObject:_encodeObject([NSValue valueWithRange:value], distantObject)];
					break;
				}
				else if(!strcmp(type, @encode(CGSize)))
				{
					CGSize value;
					[self getArgument:&value atIndex:i];
					
					[arguments addObject:_encodeObject(@(value), distantObject)];
					break;
				}
				
			default:
				[NSException raise:NSInvalidArgumentException format:@"Unsupported invocation argument type '%s'", type];
		}
		
		void* x = NULL;
		[self setArgument:&x atIndex:i];
	}
	serialized[@"arguments"] = arguments;
}

//Returns autoreleased dictionary
- (NSDictionary*)_dtx_serializedDictionaryForDistantObject:(_DTXIPCDistantObject*)distantObject
{
	NSMutableDictionary* serialized = [NSMutableDictionary dictionary];
	serialized[@"types"] = [self.methodSignature valueForKey:@"typeString"];
	
	if([self isKindOfClass:NSClassFromString(@"NSBlockInvocation")])
	{
		NSString* blockId = objc_getAssociatedObject(self, _DTXRemoteBlockIdentifierKey);
		NSParameterAssert(blockId != nil);
		serialized[@"remoteBlockIdentifier"] = blockId;
		serialized[@"blockCall"] = @YES;
		_encodeInvocation(self, serialized, 1, distantObject);
	}
	else
	{
		serialized[@"selector"] = NSStringFromSelector(self.selector);
		_encodeInvocation(self, serialized, 2, distantObject);
	}
	
	return serialized;
}

//Returns autoreleased decoded object
static id _decodeObject(NSDictionary* encodedObj, DTXIPCConnection* connection)
{
	id rv = nil;
	NSString* type = encodedObj[@"type"];
	
	if([type isEqualToString:@"block"])
	{
		const char* signature = [encodedObj[@"signature"] UTF8String];
		NSString* remoteIdentifier = encodedObj[@"remoteIdentifier"];
		
		id localForwardingBlock = __NSMakeSpecialForwardingCaptureBlock(signature, ^(NSInvocation *inv) {
			objc_setAssociatedObject(inv, _DTXRemoteBlockIdentifierKey, remoteIdentifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
			NSDictionary* serialized = [inv _dtx_serializedDictionaryForDistantObject:nil];

			NSCAssert(connection.isValid, @"Connection %@ is invalid.", connection);
			[connection.otherConnection.rootProxy _invokeRemoteBlock:serialized];
			
			NSLog(@"%@", inv);
		});
		
		objc_setAssociatedObject(localForwardingBlock, _DTXCleanupIdentifierKey, [_DTXCleanUpHandler cleanUpHandlerWithBlock:^{
			//This should be called when the block is released. This block is sent to the client code, so if they retain it, so will the remote block. Once the client code releases the block, we will notify the system to clean the remote block.
			NSCAssert(connection.isValid, @"Connection %@ is invalid.", connection);
			[connection.otherConnection.rootProxy _cleanupRemoteBlock:remoteIdentifier];
		}], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		
		rv = [localForwardingBlock autorelease];
	}
	else
	{
		NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:encodedObj[@"data"]];
		unarchiver.requiresSecureCoding = NO;
		rv = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
		[unarchiver release];
		unarchiver = nil;
	}
	
	return rv;
}

static void _decodeInvocation(NSDictionary* serialized, NSInvocation* invocation, NSUInteger firstArg, DTXIPCConnection* connection)
{
	NSMethodSignature* signature = invocation.methodSignature;
	NSArray* arguments = serialized[@"arguments"];
	
	for(NSUInteger i = firstArg; i < signature.numberOfArguments; i++)
	{
		const char* type = [signature getArgumentTypeAtIndex:i];
		NSDictionary* argument = arguments[i];
		
		switch (*type)
		{
			case 'd':
			{
				double value = [_decodeObject(argument, connection) doubleValue];
				
				[invocation setArgument:&value atIndex:i];
				break;
			}
			case 'f':
			{
				float value = [_decodeObject(argument, connection) floatValue];
				
				[invocation setArgument:&value atIndex:i];
				break;
			}
			case 'i':
			{
				int value = [_decodeObject(argument, connection) intValue];
				
				[invocation setArgument:&value atIndex:i];
				break;
			}
			case 'I':
			{
				unsigned value = [_decodeObject(argument, connection) unsignedIntValue];
				
				[invocation setArgument:&value atIndex:i];
				break;
			}
			case 'c':
			{
				char value = [_decodeObject(argument, connection) charValue];
				
				[invocation setArgument:&value atIndex:i];
				break;
			}
			case 'B':
			{
				BOOL value = [_decodeObject(argument, connection) boolValue];
				
				[invocation setArgument:&value atIndex:i];
				break;
			}
			case 'q':
			{
				long value = [_decodeObject(argument, connection) longValue];
				
				[invocation setArgument:&value atIndex:i];
				break;
			}
			case 'Q':
			{
				unsigned long value = [_decodeObject(argument, connection) unsignedLongValue];
				
				[invocation setArgument:&value atIndex:i];
				break;
			}
			case '@':
			{
				if([argument isKindOfClass:NSNull.class])
				{
					continue;
				}
				
				id value = _decodeObject(argument, connection);
				
				[invocation setArgument:&value atIndex:i];
				break;
			}
			case '{':
			{
				if (!strcmp(type, @encode(NSRange))) {
					NSRange value = [_decodeObject(argument, connection) rangeValue];
					
					[invocation setArgument:&value atIndex:i];
					break;
				} else if (!strcmp(type, @encode(CGSize))) {
					CGSize value = [_decodeObject(argument, connection) CGSizeValue];
					
					[invocation setArgument:&value atIndex:i];
					break;
				}
			}
			default:
			{
				break;
			}
		}
	}
}

//Returns autoreleased invocation
+ (instancetype)_dtx_invocationWithSerializedDictionary:(NSDictionary*)serialized remoteConnection:(nonnull DTXIPCConnection *)connection
{
	NSMethodSignature* methodSignature = nil;
	NSString* blockId = nil;
	id localBlock = nil;
	Class invocationClass = NSInvocation.class;
	SEL selector = NULL;
	
	BOOL blockCall = serialized[@"blockCall"];
	if(blockCall)
	{
		blockId = serialized[@"remoteBlockIdentifier"];
		if(blockId == nil)
		{
			[NSException raise:NSInvalidUnarchiveOperationException format:@"Block invocation has no remote block identifier"];
			
			return nil;
		}
		
		invocationClass = NSClassFromString(@"NSBlockInvocation");
		localBlock = [_DTXIPCRemoteBlockRegistry remoteBlockForIdentifier:blockId distantObject:NULL];
		methodSignature = [NSMethodSignature signatureWithObjCTypes:_Block_signature(localBlock)];
	}
	else
	{
		selector = NSSelectorFromString(serialized[@"selector"]);
		if(selector == NULL)
		{
			[NSException raise:NSInvalidUnarchiveOperationException format:@"Invocation has no selector"];
			return nil;
		}
		methodSignature = [NSMethodSignature signatureWithObjCTypes:[serialized[@"types"] UTF8String]];
	}
	
	NSInvocation* rv = [invocationClass invocationWithMethodSignature:methodSignature];
	
	if(blockCall)
	{
		_decodeInvocation(serialized, rv, 1, connection);
		rv.target = localBlock;
	}
	else
	{
		_decodeInvocation(serialized, rv, 2, connection);
		rv.selector = selector;
	}
	
	return rv;
}

@end

#endif
