//
//  _DTXIPCRemoteBlockRegistry.h
//  DetoxIPC
//
//  Created by Leo Natan (Wix) on 9/25/19.
//  Copyright © 2019 LeoNatan. All rights reserved.
//

#import <Foundation/Foundation.h>
@class _DTXIPCDistantObject;

NS_ASSUME_NONNULL_BEGIN

@interface _DTXIPCRemoteBlockRegistry : NSObject

+ (NSString*)registerRemoteBlock:(id)block distantObject:(nullable _DTXIPCDistantObject*)distantObject;
+ (id)remoteBlockForIdentifier:(NSString*)identifier distantObject:(out _DTXIPCDistantObject* __nullable * __nullable)distantObject;
+ (oneway void)retainRemoteBlock:(NSString*)identifier;
+ (oneway void)releaseRemoteBlock:(NSString*)identifier;

@end

NS_ASSUME_NONNULL_END
