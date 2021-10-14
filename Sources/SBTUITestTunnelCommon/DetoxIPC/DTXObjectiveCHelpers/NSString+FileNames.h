//
//  NSString+FileNames.h
//  DTXObjectiveCHelpers
//
//  Created by Leo Natan (Wix) on 12/07/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#if DEBUG
    #ifndef ENABLE_UITUNNEL
        #define ENABLE_UITUNNEL 1
    #endif
#endif

#if ENABLE_UITUNNEL

#import <Foundation/Foundation.h>

@interface NSString (FileNames)

@property (nonatomic, copy, readonly) NSString* stringBySanitizingForFileName;

@end

#endif
