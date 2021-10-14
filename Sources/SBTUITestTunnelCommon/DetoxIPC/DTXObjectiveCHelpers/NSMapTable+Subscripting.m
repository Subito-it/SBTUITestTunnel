//
//  NSMapTable+Subscripting.m
//  DTXObjectiveCHelpers
//
//  Created by Leo Natan (Wix) on 11/27/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#if DEBUG
    #ifndef ENABLE_UITUNNEL
        #define ENABLE_UITUNNEL 1
    #endif
#endif

#if ENABLE_UITUNNEL

#import "NSMapTable+Subscripting.h"

@implementation NSMapTable (Subscripting)

- (id)objectForKeyedSubscript:(id)key
{
	return [self objectForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id)key
{
	if (obj != nil) {
		[self setObject:obj forKey:key];
	} else {
		[self removeObjectForKey:key];
	}
}

@end

#endif
