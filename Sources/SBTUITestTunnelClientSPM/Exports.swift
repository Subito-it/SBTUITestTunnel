// Exports.swift
//
// Copyright (C) 2021 Subito.it S.r.l (www.subito.it)
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

// The tunnel is made of 4 packages
// - SBTUITestTunnelSever       Objective-C
// - SBTUITestTunnelClient      Objective-C
// - SBTUITestTunnelCommon      Objective-C
// - SBTUITestTunnelCommonSwift Swift
//
// Swift packages cannot be imported in Objective-C's umbrella headers (which is a problem for SBTUITestTunnelCommonSwift) so we create a separate module which re-exports all required modules.
// To achieve this we need to additionally rename the existing SBTUITestTunnelClient to SBTUITestTunnelClientCocoaPods so that this one can take its place.

@_exported import SBTUITestTunnelClientObjC
@_exported import SBTUITestTunnelCommon
@_exported import SBTUITestTunnelCommonSwift
