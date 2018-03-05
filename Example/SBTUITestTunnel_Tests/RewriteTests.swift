// RewriteTests.swift
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

import SBTUITestTunnel
import Foundation

class RewriteTests: XCTestCase {
    
    private let request = NetworkRequests()
    
    func testBodyRewrite() {
        let requestMatch = SBTRequestMatch(url: "httpbin.org")

        let rewrittenResponse = SBTRewrite(request: [SBTRewriteReplacement(find: "param.*\"", replace: ""),
                                                     SBTRewriteReplacement(find: "\"val.*", replace: "")],
                                           headers: [:])
        app.rewriteRequests(matching: requestMatch, response: rewrittenResponse)
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result))

        
// TODO
    }
    
    func testHeaderRewrite() {
// TODO
    }

    func testBodyRewriteAndRemove() {
// TODO
    }
    
    func testHeaderRewriteAndRemove() {
// TODO
    }

    func testHeaderRewriteAndMonitor() {
// TODO
    }

    func testHeaderRewriteAndThrottle() {
// TODO
    }

    func testHeaderRewriteAndThrottleAndMonitor() {
// TODO
    }

    func testHeaderRewriteRemoveAll() {
// TODO
    }

    func testHeaderRewriteRemoveSpecific() {
// TODO
    }
}

extension RewriteTests {
    override func setUp() {
        app.launchConnectionless { (path, params) -> String in
            return SBTUITestTunnelServer.performCommand(path, params: params)
        }
    }
}
