//
//  NSData+gzip.h
//  SBTUITestTunnel-Server
//
// https://gist.github.com/niklasberglund/5553224

@import Foundation;

@interface NSData (gzip)

- (NSData *)gzipInflate;
- (NSData *)gzipDeflate;

@end
