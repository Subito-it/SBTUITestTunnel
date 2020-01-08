//
//  NSData+gzip.h
//  SBTUITestTunnel-Server
//
//  Created by Tomas Camin on 15/02/2019.
//

@import Foundation;

@interface NSData (gzip)

- (NSData *)gzipInflate;
- (NSData *)gzipDeflate;

@end
