//
//  _DTXIPCRemoteBlockRegistry.m
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

#import "_DTXIPCRemoteBlockRegistry.h"
#import "_DTXIPCDistantObject.h"
#import "Swiftier.h"
@import ObjectiveC;
@import Darwin;

@interface _DTXRemoteBlockRegistryEntry : NSObject
@property (nonatomic, strong) NSString* identifier;
@property (nonatomic, strong) id block;
@property (nonatomic) NSInteger blockRetainCount;
@property (nonatomic, strong) _DTXIPCDistantObject* distantObject;
@end
@implementation _DTXRemoteBlockRegistryEntry @end

pthread_mutex_t _registryMutex;

static NSMutableDictionary* _registry;

@implementation _DTXIPCRemoteBlockRegistry

+ (void)load
{
	@autoreleasepool
	{
		_registry = [NSMutableDictionary new];
		pthread_mutex_init(&_registryMutex, NULL);
	}
}

+ (NSString*)registerRemoteBlock:(id)block distantObject:(_DTXIPCDistantObject*)distantObject
{
	pthread_mutex_lock_deferred_unlock(&_registryMutex);
	
	NSString* identifier = [NSUUID UUID].UUIDString;
	
	@autoreleasepool
	{
		id copied = _Block_copy(block);
		
		_DTXRemoteBlockRegistryEntry* entry = [_DTXRemoteBlockRegistryEntry new];
		entry.identifier = identifier;
		entry.block = [copied autorelease];
		entry.blockRetainCount = 1;
		entry.distantObject = distantObject;
		[entry.distantObject _enterReplyBlock];
		
		_registry[identifier] = entry;
	}
	
	return identifier;
}

+ (id)remoteBlockForIdentifier:(NSString*)identifier distantObject:(_DTXIPCDistantObject* __nullable * __nullable)distantObject;
{
	pthread_mutex_lock_deferred_unlock(&_registryMutex);
	
	_DTXRemoteBlockRegistryEntry* entry = [_registry objectForKey:identifier];
	if(distantObject != NULL)
	{
		*distantObject = entry.distantObject;
	}
	return entry.block;
}

+ (oneway void)retainRemoteBlock:(NSString*)identifier
{
	pthread_mutex_lock_deferred_unlock(&_registryMutex);
	
	_DTXRemoteBlockRegistryEntry* entry = [_registry objectForKey:identifier];
	entry.blockRetainCount += 1;
}

+ (oneway void)releaseRemoteBlock:(NSString*)identifier
{
	pthread_mutex_lock_deferred_unlock(&_registryMutex);
	
	@autoreleasepool
	{
		_DTXRemoteBlockRegistryEntry* entry = [_registry objectForKey:identifier];
		entry.blockRetainCount -= 1;
		
		if(entry.blockRetainCount == 0)
		{
			[entry.distantObject _leavelReplyBlock];
			
			[_registry removeObjectForKey:identifier];
		}
	}
}

@end
