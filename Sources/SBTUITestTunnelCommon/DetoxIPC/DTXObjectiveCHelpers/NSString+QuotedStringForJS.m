//
//  NSString+DTXQuotedStringForJS.m
//  DTXObjectiveCHelpers
//
//  Created by Leo Natan (Wix) on 4/22/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#if DEBUG
    #ifndef ENABLE_UITUNNEL
        #define ENABLE_UITUNNEL 1
    #endif
#endif

#if ENABLE_UITUNNEL

#import "NSString+QuotedStringForJS.h"
#import "Swiftier.h"

DTX_DIRECT_MEMBERS
@implementation NSString (DTXQuotedStringForJS)

- (NSString*)dtx_quotedStringRepresentationForJS
{
	NSMutableString* rv = [[self valueForKey:@"quotedStringRepresentation"] mutableCopy];
	[rv replaceOccurrencesOfString:@"\\U" withString:@"\\u" options:0 range:NSMakeRange(0, rv.length)];
	
	return rv;
}

@end

#endif
