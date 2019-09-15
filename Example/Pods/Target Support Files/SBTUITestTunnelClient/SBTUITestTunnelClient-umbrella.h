#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "SBTUITestTunnelClient.h"
#import "SBTUITestTunnelClientProtocol.h"
#import "SBTUITunneledApplication.h"
#import "XCTestCase+AppExtension.h"
#import "XCTestCase+Swizzles.h"

FOUNDATION_EXPORT double SBTUITestTunnelClientVersionNumber;
FOUNDATION_EXPORT const unsigned char SBTUITestTunnelClientVersionString[];

