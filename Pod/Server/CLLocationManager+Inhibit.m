// CLLocationManager+Inhibit.m
//
// Copyright (C) 2016 Subito.it S.r.l (www.subito.it)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if DEBUG

#import "CLLocationManager+Inhibit.h"
#import "SBTSwizzleHelpers.h"

@implementation CLLocationManager (Inhibit)

+ (void)inhibit
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SBTTestTunnelClassSwizzle(self, @selector(requestWhenInUseAuthorization), @selector(swz_inhibitClassMethod));
        SBTTestTunnelClassSwizzle(self, @selector(requestAlwaysAuthorization), @selector(swz_inhibitClassMethod));
        SBTTestTunnelInstanceSwizzle(self, @selector(startUpdatingLocation), @selector(swz_inhibitInstanceMethod));
        SBTTestTunnelInstanceSwizzle(self, @selector(startUpdatingHeading), @selector(swz_inhibitInstanceMethod));
        SBTTestTunnelInstanceSwizzle(self, @selector(startMonitoringSignificantLocationChanges), @selector(swz_inhibitInstanceMethod));
        SBTTestTunnelInstanceSwizzle(self, @selector(startMonitoringVisits), @selector(swz_inhibitInstanceMethod));
        SBTTestTunnelInstanceSwizzle(self, @selector(startMonitoringForRegion:), @selector(swz_inhibitInstanceMethodPar:));
        SBTTestTunnelInstanceSwizzle(self, @selector(startMonitoringForRegion:desiredAccuracy:), @selector(swz_inhibitInstanceMethodPar:par:));
    });
}

+ (void)swz_inhibitClassMethod
{
    return; // do nothing
}

- (void)swz_inhibitInstanceMethod
{
    return; // do nothing
}

- (void)swz_inhibitInstanceMethodPar:(id)par
{
    return; // do nothing
}

- (void)swz_inhibitInstanceMethodPar:(id)par par:(id)par
{
    return; // do nothing
}

@end

#endif
