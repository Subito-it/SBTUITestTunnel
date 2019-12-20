//
//  SBTStubResponse.swift
//  SBTUITestTunnelCommon
//
//  Created by tomas on 19/12/2019.
//

import Foundation

extension SBTStubResponse {
    public convenience init(response: Any, headers: [String: String]? = nil, contentType: String? = nil, returnCode: Int? = nil, responseTime: TimeInterval? = nil, activeIterations: Int? = nil) {
        self.init(__response: response, headers: headers, contentType: contentType, returnCode: returnCode ?? SBTStubResponse.defaultReturnCode, responseTime: responseTime ?? SBTStubResponse.defaultResponseTime, activeIterations: activeIterations ?? 0)
    }
        
    public convenience init(fileNamed: String, headers: [String: String]? = nil, returnCode: Int? = nil, responseTime: TimeInterval? = nil, activeIterations: Int? = nil) {
        self.init(__fileNamed: fileNamed, headers: headers, returnCode: returnCode ?? SBTStubResponse.defaultReturnCode, responseTime: responseTime ?? SBTStubResponse.defaultResponseTime, activeIterations: activeIterations ?? 0)
    }
}
