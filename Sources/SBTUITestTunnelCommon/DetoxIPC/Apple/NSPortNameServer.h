//
//  NSPortNameServer.h
//  DetoxIPC
//
//  Created by Leo Natan (Wix) on 10/17/19.
//  Copyright © 2019 LeoNatan. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSPortNameServer : NSObject

+ (NSPortNameServer *)systemDefaultPortNameServer;

- (nullable NSPort *)portForName:(NSString *)name;
- (nullable NSPort *)portForName:(NSString *)name host:(nullable NSString *)host;

- (BOOL)registerPort:(NSPort *)port name:(NSString *)name;

- (BOOL)removePortForName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
