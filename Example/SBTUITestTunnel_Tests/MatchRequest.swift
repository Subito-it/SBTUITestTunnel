// MatchRequest.swift
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

class MatchRequest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem])
        
        expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.tables)
        waitForExpectations(timeout: 15.0, handler: nil)
        
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    func testSimpleUrlAllMethods() {
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        
        app.cells["executeDataTaskRequest"].tap()
        XCTAssert(isNetworkResultStubbed())
        
        app.cells["executePostDataTaskRequestWithHTTPBody"].tap()
        XCTAssert(isNetworkResultStubbed())
    }
    
    func testSimpleUrlGetOnly() {
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", method:"GET"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        
        app.cells["executeDataTaskRequest"].tap()
        XCTAssert(isNetworkResultStubbed())
        
        app.cells["executePostDataTaskRequestWithHTTPBody"].tap()
        XCTAssertFalse(isNetworkResultStubbed())
    }

    func testUrlWithQueryGetOnly() {
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["param1=val1", "param2=val2"], method:"GET"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executeDataTaskRequest"].tap()
        XCTAssert(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()

        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["param2=val2", "param1=val1"], method:"GET"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executeDataTaskRequest"].tap()
        XCTAssert(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()
        
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["param1=val1&param2=val2"], method:"GET"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executeDataTaskRequest"].tap()
        XCTAssert(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()
        
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["param2=val2&param1=val1"], method:"GET"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executeDataTaskRequest"].tap()
        XCTAssertFalse(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()
        
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["param1=val1", "param3=val3"], method:"GET"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executeDataTaskRequest"].tap()
        XCTAssertFalse(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()
        
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["param1=val1", "param2=val2"], method:"POST"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executeDataTaskRequest"].tap()
        XCTAssertFalse(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()
    }
    
    func testUrlWithQueryPostOnly() {
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["param5=val5", "param6=val6"], method:"POST"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executePostDataTaskRequestWithHTTPBody"].tap()
        XCTAssert(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()
        
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["param6=val6", "param5=val5"], method:"POST"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executePostDataTaskRequestWithHTTPBody"].tap()
        XCTAssert(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()
        
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["param5=val5&param6=val6"], method:"POST"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executePostDataTaskRequestWithHTTPBody"].tap()
        XCTAssert(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()
        
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["param6=val6&param5=val5"], method:"POST"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executePostDataTaskRequestWithHTTPBody"].tap()
        XCTAssertFalse(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()
        
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["param5=val5", "param1=val1"], method:"POST"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executePostDataTaskRequestWithHTTPBody"].tap()
        XCTAssertFalse(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()
        
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["param5=val5", "param6=val6"], method:"GET"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executePostDataTaskRequestWithHTTPBody"].tap()
        XCTAssertFalse(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()
    }

    func testInvertQueryGetOnly() {
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["!param1=val1", "param2=val2"], method:"GET"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executeDataTaskRequest"].tap()
        XCTAssertFalse(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()
        
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["param1=val1", "!param2=val2"], method:"GET"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executeDataTaskRequest"].tap()
        XCTAssertFalse(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()

        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["!param1=val1", "!param2=val2"], method:"GET"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executeDataTaskRequest"].tap()
        XCTAssertFalse(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()

        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["!param9=val9", "param1=val1"], method:"GET"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executeDataTaskRequest"].tap()
        XCTAssert(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()

        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["param1=val1", "!param9=val9"], method:"GET"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executeDataTaskRequest"].tap()
        XCTAssert(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()

        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["param1=val1", "param2=val2", "!param9=val9"], method:"GET"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executeDataTaskRequest"].tap()
        XCTAssert(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()
        
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["param1=val1", "!param9=val9", "param2=val2"], method:"GET"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executeDataTaskRequest"].tap()
        XCTAssert(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()
        
        app.stubRequests(matching: SBTRequestMatch.url("httpbin.org", query: ["!param9=val9", "param1=val1", "param2=val2"], method:"GET"), returnJsonDictionary: ["stubbed": 1], returnCode: 200, responseTime: 0.0)
        app.cells["executeDataTaskRequest"].tap()
        XCTAssert(isNetworkResultStubbed())
        app.stubRequestsRemoveAll()
    }
}

extension MatchRequest {
    
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
}
