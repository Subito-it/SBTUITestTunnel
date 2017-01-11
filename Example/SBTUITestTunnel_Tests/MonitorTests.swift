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
    
    override func setUp() {
        super.setUp()
        
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem])
        
        expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.tables)
        waitForExpectations(timeout: 15.0, handler: nil)
        
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    func testMonitorFlush() {
        XCTAssert(app.monitoredRequestsFlushAll().count == 0)
        
        app.monitorRequests(matching: SBTRequestMatch.url("httpbin.org"))
        
        app.cells["executeDataTaskRequest2"].tap()
        waitForNetworkRequest()
        app.cells["executeDataTaskRequest2"].tap()
        waitForNetworkRequest()
        
        XCTAssertEqual(app.monitoredRequestsFlushAll().count, 0)
        
        app.cells["executeDataTaskRequest"].tap()
        waitForNetworkRequest()
        app.cells["executeDataTaskRequest"].tap()
        waitForNetworkRequest()
        app.cells["executeDataTaskRequest"].tap()
        waitForNetworkRequest()
        
        let requests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(app.monitoredRequestsFlushAll().count, 0)
        
        XCTAssertEqual(requests.count, 3)
        
        for request in requests {
            XCTAssert((request.responseString() ?? "").contains("httpbin.org"))
            XCTAssert(request.timestamp > 0.0)
            XCTAssert(request.requestTime > 0.0)
        }
        
        app.monitorRequestRemoveAll()

        app.cells["executeDataTaskRequest"].tap()
        waitForNetworkRequest()
        
        XCTAssertEqual(app.monitoredRequestsFlushAll().count, 0)
    }
    
    func testMonitorPeek() {
        XCTAssert(app.monitoredRequestsPeekAll().count == 0)
        
        app.monitorRequests(matching: SBTRequestMatch.url("httpbin.org"))
        
        app.cells["executeDataTaskRequest2"].tap()
        waitForNetworkRequest()
        app.cells["executeDataTaskRequest2"].tap()
        waitForNetworkRequest()
        
        XCTAssertEqual(app.monitoredRequestsPeekAll().count, 0)
        
        app.cells["executeDataTaskRequest"].tap()
        waitForNetworkRequest()
        app.cells["executeDataTaskRequest"].tap()
        waitForNetworkRequest()
        app.cells["executeDataTaskRequest"].tap()
        waitForNetworkRequest()
        
        let requests = app.monitoredRequestsPeekAll()
        XCTAssertEqual(requests.count, 3)
        let requests2 = app.monitoredRequestsPeekAll()
        XCTAssertEqual(requests2.count, 3)
        
        for request in requests {
            XCTAssert((request.responseString() ?? "").contains("httpbin.org"))
            XCTAssert(request.timestamp > 0.0)
            XCTAssert(request.requestTime > 0.0)
        }
        
        app.monitorRequestRemoveAll()
        app.monitoredRequestsFlushAll()
        
        app.cells["executeDataTaskRequest"].tap()
        waitForNetworkRequest()
        
        XCTAssertEqual(app.monitoredRequestsPeekAll().count, 0)
    }
    
    func testMonitorAndStub() {
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.monitorRequests(matching: SBTRequestMatch.url("httpbin.org"))
        
        app.cells["executeDataTaskRequest"].tap()
        XCTAssert(isNetworkResultStubbed())

        let requests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requests.count, 1)
        
        app.stubRequestsRemoveAll()
        app.monitorRequestRemoveAll()
    }
 
    func testMonitorAndThrottle() {
        app.monitorRequests(matching: SBTRequestMatch.url("httpbin.org"))
        app.throttleRequests(matching: SBTRequestMatch.url("httpbin.org"), responseTime: 5.0)
        
        app.cells["executeDataTaskRequest"].tap()
        let start = Date()
        waitForNetworkRequest()
        let delta = start.timeIntervalSinceNow

        XCTAssert(delta < -5.0)
        
        let requests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requests.count, 1)
        
        app.stubRequestsRemoveAll()
        app.monitorRequestRemoveAll()
    }
    
    func testMonitorPostRequestWithHTTPBody() {
        app.monitorRequests(matching: SBTRequestMatch.url("httpbin.org", method: "POST"))
        
        app.cells["executePostDataTaskRequestWithHTTPBody"].tap()
        waitForNetworkRequest()
        
        let requests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requests.count, 1)
        
        for request in requests {
            guard let httpBody = request.request?.httpBody else {
                XCTFail("Missing http body")
                continue
            }
            
            XCTAssertEqual(String(data: httpBody, encoding: .utf8), "&param5=val5&param6=val6")
            
            XCTAssert((request.responseString() ?? "").contains("httpbin.org"))
            XCTAssert(request.timestamp > 0.0)
            XCTAssert(request.requestTime > 0.0)
        }
        
        app.stubRequestsRemoveAll()
        app.monitorRequestRemoveAll()
    }

    func testAsyncWaitForMonitoredRequestsDoesNotTimeout() {
        app.monitorRequests(matching: SBTRequestMatch.url("httpbin.org"))
        
        let start = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.app.cells["executeDataTaskRequest3"].tap()
        }
        
        let exp = expectation(description: "Doing my thing")
        
        app.waitForMonitoredRequests(matching: SBTRequestMatch.url("httpbin.org"), timeout: 10.0) {
            didTimeout in
            
            XCTAssertFalse(didTimeout)
            let delta = start.timeIntervalSinceNow
            XCTAssert(delta < -1.0)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 15.0) {
            error in
            XCTAssertNil(error)
        }
    }

    func testSyncWaitForMonitoredRequestsDoesNotTimeout() {
        app.monitorRequests(matching: SBTRequestMatch.url("httpbin.org"))
        
        let start = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.app.cells["executeDataTaskRequest3"].tap()
        }
        
        XCTAssert(app.waitForMonitoredRequests(matching: SBTRequestMatch.url("httpbin.org"), timeout: 10.0))
        let delta = start.timeIntervalSinceNow
        
        XCTAssert(delta < -1.0)
    }

    func testAsyncWaitForMonitoredRequestsDoesTimeout() {
        app.monitorRequests(matching: SBTRequestMatch.url("httpbin.org"))
        
        let start = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            self.app.cells["executeDataTaskRequest3"].tap()
        }
        
        let exp = expectation(description: "Doing my thing")
        
        app.waitForMonitoredRequests(matching: SBTRequestMatch.url("httpbin.org"), timeout: 1.0) {
            didTimeout in
            
            XCTAssert(didTimeout)
            let delta = start.timeIntervalSinceNow
            XCTAssert(delta > -5.0)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 15.0) {
            error in
            XCTAssertNil(error)
        }
    }
    
    func testSyncWaitForMonitoredRequestsDoesTimeout() {
        app.monitorRequests(matching: SBTRequestMatch.url("httpbin.org"))
        
        let start = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            self.app.cells["executeDataTaskRequest3"].tap()
        }
        
        XCTAssertFalse(app.waitForMonitoredRequests(matching: SBTRequestMatch.url("httpbin.org"), timeout: 1.0))
        let delta = start.timeIntervalSinceNow
        
        XCTAssert(delta > -5.0)
    }
    
    func testAsyncWaitForMonitoredRequestsWithIterationsDoesNotTimeout() {
        app.monitorRequests(matching: SBTRequestMatch.url("httpbin.org"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.app.cells["executeDataTaskRequest3"].tap()
            self.app.cells["executeDataTaskRequest3"].tap()
        }
        
        let exp = expectation(description: "Doing my thing")
        
        app.waitForMonitoredRequests(matching: SBTRequestMatch.url("httpbin.org"), timeout: 15.0, iterations: 2) {
            didTimeout in
            
            XCTAssertFalse(didTimeout)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 15.0) {
            error in
            XCTAssertNil(error)
        }
    }
    
    func testSyncWaitForMonitoredRequestsWithIterationsDoesNotTimeout() {
        app.monitorRequests(matching: SBTRequestMatch.url("httpbin.org"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.app.cells["executeDataTaskRequest3"].tap()
            self.app.cells["executeDataTaskRequest3"].tap()
        }
        
        XCTAssert(app.waitForMonitoredRequests(matching: SBTRequestMatch.url("httpbin.org"), timeout: 15.0, iterations: 2))
    }
    
    func testAsyncWaitForMonitoredRequestsWithIterationsDoesTimeout() {
        app.monitorRequests(matching: SBTRequestMatch.url("httpbin.org"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.app.cells["executeDataTaskRequest3"].tap()
        }
        
        let exp = expectation(description: "Doing my thing")
        
        app.waitForMonitoredRequests(matching: SBTRequestMatch.url("httpbin.org"), timeout: 5.0, iterations: 2) {
            didTimeout in
            
            XCTAssert(didTimeout)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 15.0) {
            error in
            XCTAssertNil(error)
        }
    }
    
    func testSyncWaitForMonitoredRequestsWithIterationsDoesTimeout() {
        app.monitorRequests(matching: SBTRequestMatch.url("httpbin.org"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.app.cells["executeDataTaskRequest3"].tap()
        }
        
        XCTAssertFalse(app.waitForMonitoredRequests(matching: SBTRequestMatch.url("httpbin.org"), timeout: 5.0, iterations: 2))
    }
}

extension MonitorTests {
 
    func isNetworkResultStubbed() -> Bool {
        expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: app.textViews["result"], handler: nil)
        waitForExpectations(timeout: 10.0, handler: nil)
        
        let result = app.textViews["result"].value as! String
        let resultData = Data(base64Encoded: result)!
        let resultDict = try! JSONSerialization.jsonObject(with: resultData, options: []) as! [String: Any]
        
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        let networkBase64 = resultDict["data"] as! String
        if let networkData = Data(base64Encoded: networkBase64) {
            if let networkJson = try? JSONSerialization.jsonObject(with: networkData, options: []) as! [String: Any] {
                return (networkJson["stubbed"] != nil)
            }
        }
        
        return false
    }
    
    func waitForNetworkRequest() {
        expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: app.textViews["result"], handler: nil)
        waitForExpectations(timeout: 10.0, handler: nil)
        
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }
}
