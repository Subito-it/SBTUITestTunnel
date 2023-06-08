//
//  _DTXIPCExportedObject.m
//  DetoxIPC
//
//  Created by Leo Natan (Wix) on 9/25/19.
//  Copyright © 2019 LeoNatan. All rights reserved.
//

#import "_DTXIPCExportedObject.h"
#import "NSInvocation+DTXRemoteSerialization.h"

@implementation _DTXIPCExportedObject
{
	id _target;
	DTXIPCConnection* _connection;
	NSInvocation* _invocation;
}

+ (instancetype)_exportedObjectWithObject:(id)object connection:(DTXIPCConnection*)connection serializedInvocation:(NSDictionary*)serializedInvocation
{
	_DTXIPCExportedObject* local = [_DTXIPCExportedObject new];
	if(self)
	{
		local->_connection = connection;
		local->_target = object;
		local->_invocation = [NSInvocation _dtx_invocationWithSerializedDictionary:serializedInvocation remoteConnection:local->_connection];
		[local->_invocation retainArguments];
		if([local->_invocation isKindOfClass:NSClassFromString(@"NSBlockInvocation")] == NO)
		{
			local->_invocation.target = local->_target;
		}
	}
	return local;
}

- (oneway void)invoke
{
	[_invocation invoke];
}

@end
