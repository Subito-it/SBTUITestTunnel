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
        XCTAssertEqual(app.monitoredRequestsFlushAll().count, 0)

        XCTAssertEqual(requests.count, 3)

        for request in requests {
            XCTAssert((request.responseString()!).contains("httpbin.org"))
            XCTAssert(request.timestamp > 0.0)
            XCTAssert(request.requestTime > 0.0)
        }

        XCTAssert(app.monitorRequestRemoveAll())

        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")

        XCTAssertEqual(app.monitoredRequestsFlushAll().count, 0)
    }

    func testMonitorPeek() {
        XCTAssertEqual(app.monitoredRequestsPeekAll().count, 0)

        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))

        _ = request.dataTaskNetwork(urlString: "https://search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search?q=uitests&param3=val3&param4=val4")
        _ = request.dataTaskNetwork(urlString: "https://search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search?q=uitests&param3=val3&param4=val4")

        XCTAssertEqual(app.monitoredRequestsPeekAll().count, 0)

        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")

        let requests = app.monitoredRequestsPeekAll()
        XCTAssertEqual(requests.count, 3)
        let requests2 = app.monitoredRequestsPeekAll()
        XCTAssertEqual(requests2.count, 3)

        for request in requests {
            XCTAssert((request.responseString()!).contains("httpbin.org"))
            XCTAssert(request.timestamp > 0.0)
            XCTAssert(request.requestTime > 0.0)
        }

        XCTAssert(app.monitorRequestRemoveAll())
        app.monitoredRequestsFlushAll()

        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")

        XCTAssertEqual(app.monitoredRequestsPeekAll().count, 0)
    }

    func testMonitorAndStub() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))

        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))

        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result, expectedStubValue: 1))

        let requests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requests.count, 1)

        XCTAssert(app.stubRequestsRemoveAll())
        XCTAssert(app.monitorRequestRemoveAll())
    }

    func testMultipleMonitorForSameRequestMatch() {
        XCTContext.runActivity(named: "When adding multiple monitor for the same request match") { _ in
            XCTAssert(app.monitoredRequestsPeekAll().count == 0)

            app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
            app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
            app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
        }

        XCTContext.runActivity(named: "They should behave as only one of them has been added") { _ in
            _ = request.dataTaskNetwork(urlString: "https://search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search?q=uitests&param3=val3&param4=val4")
            _ = request.dataTaskNetwork(urlString: "https://search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search?q=uitests&param3=val3&param4=val4")

            XCTAssertEqual(app.monitoredRequestsPeekAll().count, 0)

            _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")

            let requests = app.monitoredRequestsPeekAll()
            XCTAssertEqual(requests.count, 3)
            let requests2 = app.monitoredRequestsPeekAll()
            XCTAssertEqual(requests2.count, 3)

            for request in requests {
                XCTAssert((request.responseString()!).contains("httpbin.org"))
                XCTAssert(request.timestamp > 0.0)
                XCTAssert(request.requestTime > 0.0)
            }

            XCTAssert(app.monitorRequestRemoveAll())
            app.monitoredRequestsFlushAll()

            _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")

            XCTAssertEqual(app.monitoredRequestsPeekAll().count, 0)
        }
    }

    func testMonitorAndStubDescription() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))
        app.monitorRequests(matching: SBTRequestMatch(url: ".*"))

        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result, expectedStubValue: 1))

        let result2 = request.dataTaskNetwork(urlString: "https://search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result2, expectedStubValue: 1))

        let requests3 = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requests3.count, 2)

        XCTAssert(requests3[0].description.hasSuffix(" (Stubbed)"))
        XCTAssertFalse(requests3[1].description.hasSuffix(" (Stubbed)"))

        XCTAssert(app.stubRequestsRemoveAll())
        XCTAssert(app.monitorRequestRemoveAll())
    }

    func testMonitorAndStubWithRemoveAfterTwoIterations() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1], activeIterations: 2))
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))

        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result, expectedStubValue: 1))

        let result2 = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result2, expectedStubValue: 1))

        let requests2 = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requests2.count, 2)

        XCTAssert(app.stubRequestsRemoveAll())
        XCTAssert(app.monitorRequestRemoveAll())
    }

    func testMonitorAndThrottle() {
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
        app.throttleRequests(matching: SBTRequestMatch(url: "httpbin.org"), responseTime: 5.0)

        let start = Date()
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        let delta = start.timeIntervalSinceNow

        XCTAssert(delta < -5.0 && delta > -16.0)

        let requests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requests.count, 1)

        XCTAssert(app.stubRequestsRemoveAll())
        XCTAssert(app.monitorRequestRemoveAll())
    }
    
    func testMonitorPostRequestWithHTTPBody() {
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org", method: "POST"))
        
        let smallBody = String(repeating: "a", count: 100)

        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/post", httpMethod: "POST", httpBody: smallBody)
        let requests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requests.count, 1)
        print(requests.map(\.debugDescription))

        for request in requests {
            guard let httpBody = request.request?.httpBody else {
                XCTFail("Missing http body")
                continue
            }

            XCTAssertEqual(String(data: httpBody, encoding: .utf8), smallBody)

            XCTAssert((request.responseString()!).contains("httpbin.org"))
            XCTAssert(request.timestamp > 0.0)
            XCTAssert(request.requestTime > 0.0)
        }

        XCTAssert(app.stubRequestsRemoveAll())
        XCTAssert(app.monitorRequestRemoveAll())
    }


    func testMonitorPostRequestWithHTTPLargeBody() {
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org", method: "POST"))
        
        let largeBody = String(repeating: "a", count: 20000)

        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/post", httpMethod: "POST", httpBody: largeBody)
        let requests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requests.count, 1)
        print(requests.map(\.debugDescription))

        for request in requests {
            guard let httpBody = request.request?.httpBody else {
                XCTFail("Missing http body")
                continue
            }

            XCTAssertEqual(String(data: httpBody, encoding: .utf8), largeBody)

            XCTAssert((request.responseString()!).contains("httpbin.org"))
            XCTAssert(request.timestamp > 0.0)
            XCTAssert(request.requestTime > 0.0)
        }

        XCTAssert(app.stubRequestsRemoveAll())
        XCTAssert(app.monitorRequestRemoveAll())
    }

    func testSyncWaitForMonitoredRequestsDoesNotTimeout() {
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))

        let start = Date()
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 1.0) { [weak self] in
            _ = self?.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2", httpMethod: "GET", httpBody: nil, delay: 0.0)
        }

        XCTAssert(app.waitForMonitoredRequests(matching: SBTRequestMatch(url: "httpbin.org"), timeout: 10.0))
        let delta = start.timeIntervalSinceNow

        XCTAssert(delta < -1.0, "Failed with delta: \(delta)")
    }

    func testSyncWaitForMonitoredRequestsDoesTimeout() {
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))

        let start = Date()
        XCTAssertFalse(app.waitForMonitoredRequests(matching: SBTRequestMatch(url: "httpbin.org"), timeout: 1.0))
        let delta = start.timeIntervalSinceNow

        XCTAssert(delta > -5.0)
    }

    func testSyncWaitForMonitoredRequestsWithIterationsDoesNotTimeout() {
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.0) { [weak self] in
            _ = self?.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2", httpMethod: "GET", httpBody: nil, delay: 0.0)
            _ = self?.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2", httpMethod: "GET", httpBody: nil, delay: 0.0)
        }

        XCTAssert(app.waitForMonitoredRequests(matching: SBTRequestMatch(url: "httpbin.org"), timeout: 10.0, iterations: 2))
    }

    func testSyncWaitForMonitoredRequestsWithIterationsDoesTimeout() {
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.0) { [weak self] in
            _ = self?.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2", httpMethod: "GET", httpBody: nil, delay: 0.0)
        }

        XCTAssertFalse(app.waitForMonitoredRequests(matching: SBTRequestMatch(url: "httpbin.org"), timeout: 10.0, iterations: 2))
    }

    func testRedirectForMonitoredRequestShouldMatch() {
        let redirectMatch = SBTRequestMatch(url: "httpbin.org")
        app.monitorRequests(matching: redirectMatch)
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.0) { [weak self] in
            _ = self?.request.dataTaskNetwork(urlString: "https://httpbin.org/redirect-to?url=http%3A%2F%2Fgoogle.com%2F")
        }

        XCTAssert(app.waitForMonitoredRequests(matching: redirectMatch, timeout: 10.0, iterations: 1))
    }
}

extension MonitorTests {
    override func setUp() {
        SBTUITestTunnelServer.perform(NSSelectorFromString("_connectionlessReset"))
        app.launchConnectionless { path, params -> String in
            SBTUITestTunnelServer.performCommand(path, params: params)
        }
    }
}
