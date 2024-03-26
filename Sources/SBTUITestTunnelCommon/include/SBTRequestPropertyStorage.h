//
//  SBTRequestPropertyStorage.h
//  Pods
//
//  Created by tomas on 20/02/24.
//

/// This class serves as a wrapper for NSURLProtocol to handle proxy property storage, addressing a limitation of 
/// NSURLProtocol which restricts property size to 2^14 bytes. This class stores properties in a separate in memory
/// storage assigning a unique uuid. This uuid is passed to the underlying NSURLProtocol and is used to retrieve the
/// property from the storage when needed. Properties are stored in an NSDictionary with the uuid as the key and the
/// property as the value. If this proves to be excessively optimistic memory wise an on disk storage can be implemented
/// in the future.

@import Foundation;

@interface SBTRequestPropertyStorage : NSObject

+ (void)setProperty:(nonnull id)property forKey:(nonnull NSString *)key inRequest:(nonnull NSMutableURLRequest *)request;
+ (nullable id)propertyForKey:(nonnull NSString *)key inRequest:(nonnull NSURLRequest *)request;

@end
