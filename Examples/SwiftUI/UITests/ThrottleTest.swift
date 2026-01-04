// ThrottleTest.swift
//
// Copyright (C) 2025 Subito.it S.r.l (www.subito.it)
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
import SBTUITestTunnelClient
import SBTUITestTunnelServer
import XCTest

class ThrottleTest: XCTestCase {
    private let request = NetworkRequests()

    override func setUp() {
        super.setUp()

        SBTUITestTunnelServer.perform(NSSelectorFromString("_connectionlessReset"))
        app.launchConnectionless { path, params -> String in
            SBTUITestTunnelServer.performCommand(path, params: params)
        }
    }

    func testThrottle() {
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        app.throttleRequests(matching: requestMatch, responseTime: 3.0)

        let startTime = CFAbsoluteTimeGetCurrent()
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        let endTime = CFAbsoluteTimeGetCurrent()

        XCTAssert(endTime - startTime > 2.5)
        XCTAssert(endTime - startTime < 5.0) // Allow some margin
    }

    func testThrottleRemove() {
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        let throttleId = app.throttleRequests(matching: requestMatch, responseTime: 3.0)!

        let startTime = CFAbsoluteTimeGetCurrent()
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        let endTime = CFAbsoluteTimeGetCurrent()

        XCTAssert(endTime - startTime > 2.5)

        app.throttleRequestRemove(withId: throttleId)

        let startTime2 = CFAbsoluteTimeGetCurrent()
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        let endTime2 = CFAbsoluteTimeGetCurrent()

        XCTAssert(endTime2 - startTime2 < 2.0)
    }

    func testThrottleRemoveAll() {
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        app.throttleRequests(matching: requestMatch, responseTime: 3.0)

        let startTime = CFAbsoluteTimeGetCurrent()
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        let endTime = CFAbsoluteTimeGetCurrent()

        XCTAssert(endTime - startTime > 2.5)

        app.throttleRequestRemoveAll()

        let startTime2 = CFAbsoluteTimeGetCurrent()
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        let endTime2 = CFAbsoluteTimeGetCurrent()

        XCTAssert(endTime2 - startTime2 < 2.0)
    }
}
