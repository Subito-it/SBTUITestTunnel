// ThrottleTests.swift
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

import SBTUITestTunnelClient
import SBTUITestTunnelServer
import Foundation
import XCTest

class ThrottleTests: XCTestCase {
    
    private let request = NetworkRequests()
    
    func testThrottle() {
        app.throttleRequests(matching: SBTRequestMatch(url: "httpbin.org"), responseTime: 5.0)

        let start = Date()
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        let delta = start.timeIntervalSinceNow
        
        XCTAssert(delta < -5.0 && delta > -8.0)
    }

    func testThrottleOverridesStubResponseTime() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))
        app.throttleRequests(matching: SBTRequestMatch(url: "httpbin.org"), responseTime: 5.0)
        
        let start = Date()
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        let delta = start.timeIntervalSinceNow
        
        XCTAssert(delta < -5.0 && delta > -8.0)
    }

    func testThrottleOverridesStubResponseTime2() {
        app.throttleRequests(matching: SBTRequestMatch(url: "httpbin.org"), responseTime: 5.0)
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))
        
        let start = Date()
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        let delta = start.timeIntervalSinceNow
        
        XCTAssert(delta < -5.0 && delta > -8.0)
    }
    
    func testThrottleAndRemoveAll() {
        app.throttleRequests(matching: SBTRequestMatch(url: "httpbin.org"), responseTime: 5.0)
        
        let start = Date()
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        let delta = start.timeIntervalSinceNow
        
        XCTAssert(delta < -5.0 && delta > -8.0)
        
        XCTAssert(app.throttleRequestRemoveAll())
        let start2 = Date()
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        let delta2 = start2.timeIntervalSinceNow
        
        XCTAssert(delta2 > -2.0, "Got \(delta2)")
    }
    
    func testThrottleAndRemoveSpecific() {
        let requestId = app.throttleRequests(matching: SBTRequestMatch(url: "httpbin.org"), responseTime: 5.0) ?? ""
        
        let start = Date()
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        let delta = start.timeIntervalSinceNow
        
        XCTAssert(delta < -5.0 && delta > -8.0)
        
        XCTAssert(app.throttleRequestRemove(withId: requestId))
        let start2 = Date()
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        let delta2 = start2.timeIntervalSinceNow
        
        XCTAssert(delta2 > -2.0)
    }
    
    func testTripleThrottle() {
        app.throttleRequests(matching: SBTRequestMatch(url: "httpbin.org"), responseTime: 1.0)
        app.throttleRequests(matching: SBTRequestMatch(url: "httpbin.org/g"), responseTime: 2.0)
        app.throttleRequests(matching: SBTRequestMatch(url: "httpbin.org/ge"), responseTime: 3.0)
        
        let start = Date()
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        let delta = start.timeIntervalSinceNow
        
        XCTAssert(delta < -3.0 && delta > -15.0)
    }
}

extension ThrottleTests {
    override func setUp() {
        app.launchConnectionless { (path, params) -> String in
            return SBTUITestTunnelServer.performCommand(path, params: params)
        }
    }
}
