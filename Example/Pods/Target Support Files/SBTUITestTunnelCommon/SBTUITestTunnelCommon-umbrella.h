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

#import "SBTMonitoredNetworkRequest.h"
#import "SBTRegularExpressionMatcher.h"
#import "SBTSwizzleHelpers.h"
#import "SBTUITestTunnel.h"
#import "SBTUITestTunnelCommon.h"

FOUNDATION_EXPORT double SBTUITestTunnelCommonVersionNumber;
FOUNDATION_EXPORT const unsigned char SBTUITestTunnelCommonVersionString[];

