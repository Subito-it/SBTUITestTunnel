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

import SBTUITestTunnel
import Foundation

class ThrottleTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem])
        
        expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.tables)
        waitForExpectations(timeout: 15.0, handler: nil)
        
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    func testThrottle() {
        app.throttleRequests(matching: SBTRequestMatch.url("httpbin.org"), responseTime: 5.0)
        
        app.cells["executeDataTaskRequest"].tap()
        let start = Date()
        waitForNetworkRequest()
        let delta = start.timeIntervalSinceNow
        
        XCTAssert(delta < -5.0)
    }

    func testThrottleOverridesStubResponseTime() {
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.throttleRequests(matching: SBTRequestMatch.url("httpbin.org"), responseTime: 5.0)
        
        app.cells["executeDataTaskRequest"].tap()
        let start = Date()
        waitForNetworkRequest()
        let delta = start.timeIntervalSinceNow
        
        XCTAssert(delta < -5.0)
    }

    func testThrottleOverridesStubResponseTime2() {
        app.throttleRequests(matching: SBTRequestMatch.url("httpbin.org"), responseTime: 5.0)
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        
        app.cells["executeDataTaskRequest"].tap()
        let start = Date()
        waitForNetworkRequest()
        let delta = start.timeIntervalSinceNow
        
        XCTAssert(delta < -5.0)
    }
}

extension ThrottleTests {
 
    func waitForNetworkRequest() {
        expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: app.textViews["result"], handler: nil)
        waitForExpectations(timeout: 10.0, handler: nil)
        
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }
}
