// SBTUITestTunnelNetworkUtility.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Network utilities for SBTUITestTunnel
 */
@interface SBTUITestTunnelNetworkUtility : NSObject

/**
 *  Reserve an available port for socket communication
 *
 *  @return The reserved port number if successful, negative number if error
 */
+ (NSInteger)reserveSocketPort;

@end

NS_ASSUME_NONNULL_END
