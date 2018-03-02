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

import SBTUITestTunnel
import Foundation

class MonitorTests: XCTestCase {
    
    private let request = NetworkRequests()
    
    func testMonitorFlush() {
        XCTAssert(app.monitoredRequestsFlushAll().count == 0)
        
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
        
        _ = request.dataTaskNetwork(urlString: "http://requestb.in/1cme69x1?param3=val3&param4=val4")
        _ = request.dataTaskNetwork(urlString: "http://requestb.in/1cme69x1?param3=val3&param4=val4")
        
        XCTAssertEqual(app.monitoredRequestsFlushAll().count, 0)
        
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        
        let requests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(app.monitoredRequestsFlushAll().count, 0)
        
        XCTAssertEqual(requests.count, 3)
        
        for request in requests {
            XCTAssert((request.responseString()!).contains("httpbin.org"))
            XCTAssert(request.timestamp > 0.0)
            XCTAssert(request.requestTime > 0.0)
        }
        
        app.monitorRequestRemoveAll()

        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        
        XCTAssertEqual(app.monitoredRequestsFlushAll().count, 0)
    }

    func testMonitorPeek() {
        XCTAssert(app.monitoredRequestsPeekAll().count == 0)
        
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
        
        _ = request.dataTaskNetwork(urlString: "http://requestb.in/1cme69x1?param3=val3&param4=val4")
        _ = request.dataTaskNetwork(urlString: "http://requestb.in/1cme69x1?param3=val3&param4=val4")
        
        XCTAssertEqual(app.monitoredRequestsPeekAll().count, 0)
        
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        
        let requests = app.monitoredRequestsPeekAll()
        XCTAssertEqual(requests.count, 3)
        let requests2 = app.monitoredRequestsPeekAll()
        XCTAssertEqual(requests2.count, 3)
        
        for request in requests {
            XCTAssert((request.responseString()!).contains("httpbin.org"))
            XCTAssert(request.timestamp > 0.0)
            XCTAssert(request.requestTime > 0.0)
        }
        
        app.monitorRequestRemoveAll()
        app.monitoredRequestsFlushAll()
        
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        
        XCTAssertEqual(app.monitoredRequestsPeekAll().count, 0)
    }
    
    func testMonitorAndStub() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))
        
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result))

        let requests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requests.count, 1)
        
        app.stubRequestsRemoveAll()
        app.monitorRequestRemoveAll()
    }

    func testMonitorTwice() {
        // should not crash
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
    }
    
    func testMonitorAndStubDescription() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))
        app.monitorRequests(matching: SBTRequestMatch(url: ".*"))
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result))
        
        let result2 = request.dataTaskNetwork(urlString: "http://requestb.in/1cme69x1?param3=val3&param4=val4")
        XCTAssertFalse(request.isStubbed(result2))

        let requests3 = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requests3.count, 2)
        
        XCTAssert(requests3[0].description.hasSuffix(" (Stubbed)"))
        XCTAssertFalse(requests3[1].description.hasSuffix(" (Stubbed)"))
        
        app.stubRequestsRemoveAll()
        app.monitorRequestRemoveAll()
    }

    func testMonitorAndStubWithRemoveAfterTwoIterations() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]), removeAfterIterations: 2)
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result))
        
        let result2 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result2))
        
        let requests2 = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requests2.count, 2)
        
        app.stubRequestsRemoveAll()
        app.monitorRequestRemoveAll()
    }

    func testMonitorAndThrottle() {
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
        app.throttleRequests(matching: SBTRequestMatch(url: "httpbin.org"), responseTime: 5.0)
        
        let start = Date()
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        let delta = start.timeIntervalSinceNow

        XCTAssert(delta < -5.0 && delta > -8.0)
        
        let requests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requests.count, 1)
        
        app.stubRequestsRemoveAll()
        app.monitorRequestRemoveAll()
    }

    func testMonitorPostRequestWithHTTPBody() {
        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org", method: "POST"))
        
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/post", httpMethod: "POST", httpBody: "&param5=val5&param6=val6")
        let requests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requests.count, 1)
        print(requests.map { $0.debugDescription })
        
        for request in requests {
            guard let httpBody = request.request?.httpBody else {
                XCTFail("Missing http body")
                continue
            }
            
            XCTAssertEqual(String(data: httpBody, encoding: .utf8), "&param5=val5&param6=val6")
            
            XCTAssert((request.responseString()!).contains("httpbin.org"))
            XCTAssert(request.timestamp > 0.0)
            XCTAssert(request.requestTime > 0.0)
        }
        
        app.stubRequestsRemoveAll()
        app.monitorRequestRemoveAll()
    }

//    func testAsyncWaitForMonitoredRequestsDoesNotTimeout() {
//        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
//        
//        let start = Date()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//            self?.app.cells["executeDataTaskRequest3"].tap()
//        }
//        
//        let exp = expectation(description: "Doing my thing")
//        
//        app.waitForMonitoredRequests(matching: SBTRequestMatch(url: "httpbin.org"), timeout: 10.0) {
//            didTimeout in
//            
//            XCTAssertFalse(didTimeout)
//            let delta = start.timeIntervalSinceNow
//            XCTAssert(delta < -1.0)
//            exp.fulfill()
//        }
//        
//        waitForExpectations(timeout: 15.0) {
//            error in
//            XCTAssertNil(error)
//        }
//    }
//
//    func testSyncWaitForMonitoredRequestsDoesNotTimeout() {
//        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
//        
//        let start = Date()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//            self?.app.cells["executeDataTaskRequest3"].tap()
//        }
//        
//        XCTAssert(app.waitForMonitoredRequests(matching: SBTRequestMatch(url: "httpbin.org"), timeout: 10.0))
//        let delta = start.timeIntervalSinceNow
//        
//        XCTAssert(delta < -1.0)
//    }
//
//    func testAsyncWaitForMonitoredRequestsDoesTimeout() {
//        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
//        
//        let start = Date()
//        let exp = expectation(description: "Doing my thing")
//        
//        app.waitForMonitoredRequests(matching: SBTRequestMatch(url: "httpbin.org"), timeout: 1.0) {
//            didTimeout in
//            
//            XCTAssert(didTimeout)
//            let delta = start.timeIntervalSinceNow
//            XCTAssert(delta > -5.0)
//            exp.fulfill()
//        }
//        
//        waitForExpectations(timeout: 15.0) {
//            error in
//            XCTAssertNil(error)
//        }
//    }
//    
//    func testSyncWaitForMonitoredRequestsDoesTimeout() {
//        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
//        
//        let start = Date()
//        XCTAssertFalse(app.waitForMonitoredRequests(matching: SBTRequestMatch(url: "httpbin.org"), timeout: 1.0))
//        let delta = start.timeIntervalSinceNow
//        
//        XCTAssert(delta > -5.0)
//    }
//    
//    func testAsyncWaitForMonitoredRequestsWithIterationsDoesNotTimeout() {
//        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//            self?.app.cells["executeDataTaskRequest3"].tap()
//            Thread.sleep(forTimeInterval: 1.0)
//            self?.app.cells["executeDataTaskRequest3"].tap()
//        }
//        
//        let exp = expectation(description: "Doing my thing")
//        
//        app.waitForMonitoredRequests(matching: SBTRequestMatch(url: "httpbin.org"), timeout: 15.0, iterations: 2) {
//            didTimeout in
//            
//            XCTAssertFalse(didTimeout)
//            exp.fulfill()
//        }
//        
//        waitForExpectations(timeout: 15.0) {
//            error in
//            XCTAssertNil(error)
//        }
//    }
//    
//    func testSyncWaitForMonitoredRequestsWithIterationsDoesNotTimeout() {
//        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//            self?.app.cells["executeDataTaskRequest3"].tap()
//            self?.app.cells["executeDataTaskRequest3"].tap()
//        }
//        
//        XCTAssert(app.waitForMonitoredRequests(matching: SBTRequestMatch(url: "httpbin.org"), timeout: 15.0, iterations: 2))
//    }
//    
//    func testAsyncWaitForMonitoredRequestsWithIterationsDoesTimeout() {
//        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//            self?.app.cells["executeDataTaskRequest3"].tap()
//        }
//        
//        let exp = expectation(description: "Doing my thing")
//        
//        app.waitForMonitoredRequests(matching: SBTRequestMatch(url: "httpbin.org"), timeout: 5.0, iterations: 2) {
//            didTimeout in
//            
//            XCTAssert(didTimeout)
//            exp.fulfill()
//        }
//        
//        waitForExpectations(timeout: 15.0) {
//            error in
//            XCTAssertNil(error)
//        }
//    }
//    
//    func testSyncWaitForMonitoredRequestsWithIterationsDoesTimeout() {
//        app.monitorRequests(matching: SBTRequestMatch(url: "httpbin.org"))
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//            self?.app.cells["executeDataTaskRequest3"].tap()
//        }
//        
//        XCTAssertFalse(app.waitForMonitoredRequests(matching: SBTRequestMatch(url: "httpbin.org"), timeout: 5.0, iterations: 2))
//    }
//    
//    func testRedictForMonitoredRequestShouldMatch() {
//        let redirectMatch = SBTRequestMatch(url: "httpbin.org")
//        app.monitorRequests(matching: redirectMatch)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//            self?.app.cells["executeRequestWithRedirect"].tap()
//        }
//        
//        XCTAssert(app.waitForMonitoredRequests(matching: redirectMatch, timeout: 5.0, iterations: 1))
//    }
//}
}

extension MonitorTests {
    override func setUp() {
        app.launchConnectionless { (path, params) -> String in
            return SBTUITestTunnelServer.performCommand(path, params: params)
        }
    }
    
    override func tearDown() {
        app.monitorRequestRemoveAll()
        app.stubRequestsRemoveAll()
        app.blockCookiesRequestsRemoveAll()
        app.throttleRequestRemoveAll()
    }
}
