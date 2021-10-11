//
//  _DTXIPCDistantObject.h
//  DetoxIPC
//
//  Created by Leo Natan (Wix) on 9/24/19.
//  Copyright © 2019 LeoNatan. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DTXIPCConnection;
@class _DTXIPCExportedObject;

NS_ASSUME_NONNULL_BEGIN

@interface _DTXIPCDistantObject : NSObject

+ (instancetype)_distantObjectWithConnection:(DTXIPCConnection*)connection synchronous:(BOOL)synchronous errorBlock:(void(^ __nullable)(NSError*))errorBlock;
- (void)_enterReplyBlock;
- (void)_leavelReplyBlock;
- (BOOL)_enqueueSynchronousExportedObjectInvocation:(_DTXIPCExportedObject*)object;

@property (nonatomic, readonly, getter=isSynchronous) BOOL synchronous;

@end

NS_ASSUME_NONNULL_END
