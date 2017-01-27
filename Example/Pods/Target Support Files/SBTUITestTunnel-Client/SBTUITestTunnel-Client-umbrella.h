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

#import "NSString+SwiftDemangle.h"
#import "SBTUITunneledApplication.h"
#import "XCTestCase+Extension.h"
#import "NSURLRequest+HTTPBodyFix.h"
#import "NSURLRequest+SBTUITestTunnelMatch.h"
#import "SBTMonitoredNetworkRequest.h"
#import "SBTRequestMatch.h"
#import "SBTSwizzleHelpers.h"
#import "SBTUITestTunnel.h"

FOUNDATION_EXPORT double SBTUITestTunnelVersionNumber;
FOUNDATION_EXPORT const unsigned char SBTUITestTunnelVersionString[];

