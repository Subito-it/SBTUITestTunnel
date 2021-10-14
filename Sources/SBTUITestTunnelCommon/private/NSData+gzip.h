//
//  NSData+gzip.h
//  SBTUITestTunnel-Server
//
// https://gist.github.com/niklasberglund/5553224

#if DEBUG
    #ifndef ENABLE_UITUNNEL
        #define ENABLE_UITUNNEL 1
    #endif
#endif

#if ENABLE_UITUNNEL

@import Foundation;

@interface NSData (gzip)

- (NSData *)gzipInflate;
- (NSData *)gzipDeflate;

@end

#endif
