// SBTUITestTunnelCommon.h
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
#endif

#import "SBTMonitoredNetworkRequest.h"
#import "SBTRequestMatch.h"
#import "SBTRewrite.h"
#import "SBTRewriteReplacement.h"
#import "SBTStubFailureResponse.h"
#import "SBTStubResponse.h"
#import "SBTSwizzleHelpers.h"
#import "SBTUITestTunnel.h"
#import "SBTIPCTunnel.h"

#if ENABLE_UITUNNEL

#ifdef SPM
    #import "../DetoxIPC/DTXIPCConnection.h"
#endif

#endif
