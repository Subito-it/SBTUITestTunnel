// SBTStubResponse+Swift.swift
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

import Foundation
#if SWIFT_PACKAGE
    import SBTUITestTunnelCommon
#endif

#if DEBUG || ENABLE_UITUNNEL
public extension SBTStubResponse {
    convenience init(response: Any, headers: [String: String]? = nil, contentType: String? = nil, returnCode: Int? = nil, responseTime: TimeInterval? = nil, activeIterations: Int = 0) {
        self.init(_response: response as! NSObject, _headers: headers, _contentType: contentType, _returnCode: returnCode ?? -1, _responseTime: responseTime ?? NSTimeIntervalSince1970, _activeIterations: activeIterations)
    }

    convenience init(fileNamed: String, headers: [String: String]? = nil, returnCode: Int? = nil, responseTime: TimeInterval? = nil, activeIterations: Int = 0) {
        self.init(_fileNamed: fileNamed, _headers: headers, _returnCode: returnCode ?? -1, _responseTime: responseTime ?? NSTimeIntervalSince1970, _activeIterations: activeIterations)
    }
}
#endif
