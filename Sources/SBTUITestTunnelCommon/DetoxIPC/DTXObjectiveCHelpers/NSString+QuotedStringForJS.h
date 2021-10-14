//
//  NSString+QuotedStringForJS.h
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

#import <Foundation/Foundation.h>

@interface NSString (DTXQuotedStringForJS)

- (NSString*)dtx_quotedStringRepresentationForJS;

@end

#endif
