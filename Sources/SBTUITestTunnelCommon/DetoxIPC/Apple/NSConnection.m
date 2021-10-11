//
//  NSConnection.m
//  DetoxIPC
//
//  Created by tomas on 16/10/2019.
//  Copyright © 2019 LeoNatan. All rights reserved.
//

// Default implementation for NSConnection which is not available on iOS physical devices which allows to properly link the library

#import "NSConnection.h"

#if !TARGET_OS_SIMULATOR

NSString *const  _Nonnull __strong NSConnectionDidDieNotification = @"NSConnectionDidDieNotification";

@implementation NSConnection

- (void)run
{
    NSAssert(NO, @"NSConnection is not available on iOS devices");
    return;
}

- (BOOL)isValid
{
    return NO;
}

- (void)invalidate
{
    return;
}

- (void)addRunLoop:(NSRunLoop *)runloop
{
    return;
}

- (void)removeRunLoop:(NSRunLoop *)runloop
{
    return;
}

- (void)runInNewThread
{
    return;
}

- (BOOL)registerName:(nullable NSString *) name
{
    return NO;
}

+ (instancetype)connectionWithRegisteredName:(NSString *)name host:(nullable NSString *)hostName
{
    NSAssert(NO, @"NSConnection is not available on iOS devices");
    return nil;
}

+ (instancetype)connectionWithReceivePort:(nullable NSPort *)receivePort sendPort:(nullable NSPort *)sendPort
{
    NSAssert(NO, @"NSConnection is not available on iOS devices");
    return nil;
}

@end

#endif
