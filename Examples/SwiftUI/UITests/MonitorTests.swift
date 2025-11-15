// MonitorTests.swift
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

import Foundation
import SBTUITestTunnelClient
import SBTUITestTunnelServer
import XCTest

class MonitorTests: XCTestCase {
    private let request = NetworkRequests()

    func testMonitorRemoveSpecific() {
        let requestId = app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org")) ?? ""

        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertEqual(app.monitoredRequestsFlushAll().count, 1)

        XCTAssert(app.monitorRequestRemove(withId: requestId))
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertEqual(app.monitoredRequestsFlushAll().count, 0)
    }

    func testMonitorFlush() {
        XCTAssertEqual(app.monitoredRequestsFlushAll().count, 0)

        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))

        _ = request.dataTaskNetwork(urlString: "https://search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search?q=uitests&param3=val3&param4=val4")
        _ = request.dataTaskNetwork(urlString: "https://search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search?q=uitests&param3=val3&param4=val4")

        XCTAssertEqual(app.monitoredRequestsFlushAll().count, 0)

        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")

        let requests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requests.count, 3)

        let requestsAgain = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requestsAgain.count, 0)
    }

    func testMonitorRemoveAll() {
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))

        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertEqual(app.monitoredRequestsFlushAll().count, 1)

        XCTAssert(app.monitorRequestRemoveAll())
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertEqual(app.monitoredRequestsFlushAll().count, 0)
    }

    func testMonitorPeekAll() {
        XCTAssertEqual(app.monitoredRequestsPeekAll().count, 0)

        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))

        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")

        let requests = app.monitoredRequestsPeekAll()
        XCTAssertEqual(requests.count, 2)

        let requestsAgain = app.monitoredRequestsPeekAll()
        XCTAssertEqual(requestsAgain.count, 2)

        let flushedRequests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(flushedRequests.count, 2)
    }
}
