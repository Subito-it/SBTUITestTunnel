//
//  DTXIPCListener.h
//  DetoxIPC
//
//  Created by Leo Natan (Wix) on 9/24/19.
//  Copyright © 2019 LeoNatan. All rights reserved.
//

#if DEBUG
    #ifndef ENABLE_UITUNNEL
        #define ENABLE_UITUNNEL 1
    #endif
#endif

#if ENABLE_UITUNNEL

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DTXIPCListener : NSObject



@end

NS_ASSUME_NONNULL_END

#endif
