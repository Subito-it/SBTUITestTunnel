//
//  Header.h
//  DetoxIPC
//
//  Created by Leo Natan (Wix) on 10/16/19.
//  Copyright © 2019 LeoNatan. All rights reserved.
//

#if DEBUG
    #ifndef ENABLE_UITUNNEL
        #define ENABLE_UITUNNEL 1
    #endif
#endif

#if ENABLE_UITUNNEL

#import <Foundation/Foundation.h>

#define DTXIPC_DEPRECATED_API(x) __attribute__((deprecated(x)))

extern NSErrorDomain const DTXIPCErrorDomain;

#endif
