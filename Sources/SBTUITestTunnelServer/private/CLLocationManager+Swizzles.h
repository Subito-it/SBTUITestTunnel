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

#if !DISABLE_UITUNNEL_SWIZZLING

@import CoreLocation;

@interface CLLocationManager (Swizzles)

+ (void)setStubbedAuthorizationStatus:(NSString *)autorizationStatus;
+ (void)setStubbedAccuracyAuthorization:(NSString *)accuracyAuthorization API_AVAILABLE(ios(14));
+ (void)setStubbedCurrentLocation:(CLLocation *)location;
+ (void)loadSwizzlesWithInstanceHashTable:(NSMapTable<CLLocationManager *, id<CLLocationManagerDelegate>>*)hashTable;
+ (void)removeSwizzles;

- (id<CLLocationManagerDelegate>)stubbedDelegate;
- (CLLocation *)location;

@end

#endif
