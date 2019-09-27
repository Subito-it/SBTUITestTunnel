// CLLocationManager+Swizzles.h
//
// Copyright (C) 2018 Subito.it S.r.l (www.subito.it)
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
    #ifndef ENABLE_UITUNNEL
        #define ENABLE_UITUNNEL 1
    #endif

    #ifndef ENABLE_UITUNNEL_SWIZZLING
        #define ENABLE_UITUNNEL_SWIZZLING 1
    #endif
#endif

#if ENABLE_UITUNNEL && ENABLE_UITUNNEL_SWIZZLING

#import <CoreLocation/CLLocationManager.h>

@interface CLLocationManager (Swizzles)

+ (void)loadSwizzlesWithInstanceHashTable:(NSMapTable<CLLocationManager *, id<CLLocationManagerDelegate>>*)hashTable
                      authorizationStatus:(NSString *)autorizationStatus;
+ (void)removeSwizzles;

- (id<CLLocationManagerDelegate>)stubbedDelegate;

@end

#endif
