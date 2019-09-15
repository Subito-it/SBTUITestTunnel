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

#import "NSData+gzip.h"
#import "NSString+SwiftDemangle.h"
#import "NSURLRequest+HTTPBodyFix.h"
#import "NSURLRequest+SBTUITestTunnelMatch.h"
#import "SBTMonitoredNetworkRequest.h"
#import "SBTRequestMatch.h"
#import "SBTRewrite.h"
#import "SBTStubResponse.h"
#import "SBTSwizzleHelpers.h"
#import "SBTUITestTunnel.h"

FOUNDATION_EXPORT double SBTUITestTunnelCommonVersionNumber;
FOUNDATION_EXPORT const unsigned char SBTUITestTunnelCommonVersionString[];

