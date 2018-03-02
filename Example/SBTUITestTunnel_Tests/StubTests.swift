// StubTests.swift
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

class StubTests: XCTestCase {
    
    private let request = NetworkRequests()
    
    func testStubRemoveWithID() {
        let stubId = app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))!
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result))
        
        
        XCTAssert(app.stubRequestsRemove(withId: stubId))
        let result2 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result2))
    }
    
    func testStubRemoveAll() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result))

        XCTAssert(app.stubRequestsRemoveAll())
        let result2 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result2))
    }
    
    func testStubAddTwice() {
        // first rule should win
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["not-stubbed": 99]))
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result))
        
        XCTAssert(app.stubRequestsRemoveAll())
        let result2 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result2))
    }
    
    func testStubAndRemoveCommand() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]), removeAfterIterations: 2)

        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result))
        let result2 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result2))
        let result3 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result3))
 
        XCTAssert(app.stubRequestsRemoveAll())
        let result4 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result4))
    }
    
    func testStubDataTask() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result))
    }
    
//    func testStubUploadDataTask() {
//        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))
//        
//        app.cells["executeUploadDataTaskRequest"].tap()
//        XCTAssert(request.isStubbed(result))
//    }
//    
//    func testStubBackgroundUploadDataTask() {
//        // background tasks are not managed by the app itself and therefore cannot be stubbed 
//        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))
//        
//        app.cells["executeBackgroundUploadDataTaskRequest"].tap()
//        XCTAssertFalse(request.isStubbed(result))
//    }
//    
//    func testStubResponseDelay() {
//        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1], responseTime: 5.0))
//        
//        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
//        let start = Date()
//        XCTAssert(request.isStubbed(result))
//        let delta = start.timeIntervalSinceNow
//        XCTAssert(delta < -5.0)
//    }
//    
//    func testStubResponseCode() {
//        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1], returnCode: 401))
//        
//        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
//        XCTAssert(networkReturnCode() == 401)
//    }
//
//    func testStubHeaders() {
//      let customHeaders = ["X-Custom": "Custom"]
//      let genericReturnString = "Hello world"
//      let genericReturnData = genericReturnString.data(using: .utf8)!
//
//      app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: genericReturnData, headers: customHeaders, contentType: "text/plain", returnCode: 200, responseTime: 5.0))
//
//      var expectedHeaders = customHeaders
//      expectedHeaders["Content-Length"] = String(genericReturnData.count)
//      expectedHeaders["Content-Type"] = "text/plain"
//
//      let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
//      XCTAssert(networkReturnHeaders() == expectedHeaders)
//    }
//    
//    func testStubGenericReturnData() {
//        let genericReturnString = "Hello world"
//        let genericReturnData = genericReturnString.data(using: .utf8)!
//        
//        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: genericReturnData, headers: [:], contentType: "text/plain", returnCode: 200, responseTime: 0.0))
//        
//        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
//        
//        expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: app.textViews["result"], handler: nil)
//        waitForExpectations(timeout: 10.0, handler: nil)
//        
//        let result = app.textViews["result"].value as! String
//        let resultData = Data(base64Encoded: result)!
//        let resultDict = try! JSONSerialization.jsonObject(with: resultData, options: []) as! [String: Any]
//        
//        let networkBase64 = resultDict["data"] as! String
//        let networkString = String(data: Data(base64Encoded: networkBase64)!, encoding: .utf8)
//
//        XCTAssertEqual(networkString, genericReturnString)
//    }
//    
//    func testStubPostRequest() {
//        let stubId1 = app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))!
//        app.cells["executeUploadDataTaskRequest"].tap()
//        XCTAssert(request.isStubbed(result))
//        
//        XCTAssert(app.stubRequestsRemove(withId: stubId1))
//        app.cells["executeUploadDataTaskRequest"].tap()
//        XCTAssertFalse(request.isStubbed(result))
//        
//        let stubId2 = app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", method: "POST"), response: SBTStubResponse(response: ["stubbed": 1]))!
//        app.cells["executeUploadDataTaskRequest"].tap()
//        XCTAssert(request.isStubbed(result))
//
//        XCTAssert(app.stubRequestsRemove(withId: stubId2))
//        app.cells["executeUploadDataTaskRequest"].tap()
//        XCTAssertFalse(request.isStubbed(result))
//
//        let stubId3 = app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))!
//        app.cells["executeUploadDataTaskRequest"].tap()
//        XCTAssertFalse(request.isStubbed(result))
//        
//        XCTAssert(app.stubRequestsRemove(withId: stubId3))
//        app.cells["executeUploadDataTaskRequest"].tap()
//        XCTAssertFalse(request.isStubbed(result))
//    }
//    
//    func testStubPutRequest() {
//        let stubId1 = app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", method: "PUT"), response: SBTStubResponse(response: ["stubbed": 1]))!
//        app.cells["executeUploadDataTaskRequest2"].tap()
//        XCTAssert(request.isStubbed(result))
//        
//        XCTAssert(app.stubRequestsRemove(withId: stubId1))
//        app.cells["executeUploadDataTaskRequest2"].tap()
//        XCTAssertFalse(request.isStubbed(result))
//        
//        let stubId2 = app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", method: "POST"), response: SBTStubResponse(response: ["stubbed": 1]))!
//        app.cells["executeUploadDataTaskRequest2"].tap()
//        XCTAssertFalse(request.isStubbed(result))
//        
//        XCTAssert(app.stubRequestsRemove(withId: stubId2))
//        app.cells["executeUploadDataTaskRequest2"].tap()
//        XCTAssertFalse(request.isStubbed(result))
//        
//        let stubId3 = app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))!
//        app.cells["executeUploadDataTaskRequest2"].tap()
//        XCTAssertFalse(request.isStubbed(result))
//        
//        XCTAssert(app.stubRequestsRemove(withId: stubId3))
//        app.cells["executeUploadDataTaskRequest2"].tap()
//        XCTAssertFalse(request.isStubbed(result))
//    }
//    
//    func testStubResponseDefaultOverriders() {
//        let contentType = "application/test"
//        let responseText = "expected text"
//        
//        SBTStubResponse.setDefaultReturnCode(404)
//        SBTStubResponse.setDefaultResponseTime(5.0)
//        SBTStubResponse.setStringDefaultContentType(contentType)
//        
//        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: responseText))
//        
//        var expectedHeaders = [String: String]()
//        expectedHeaders["Content-Length"] = String(responseText.count)
//        expectedHeaders["Content-Type"] = contentType
//        
//        var start = Date()
//        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
//        XCTAssert(networkReturnHeaders() == expectedHeaders)
//        var delta = start.timeIntervalSinceNow
//        XCTAssert(delta < -5.0)
//        
//        SBTStubResponse.resetUnspecifiedDefaults()
//        app.stubRequestsRemoveAll()
//        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: responseText))
//        
//        expectedHeaders["Content-Type"] = "text/plain"
//
//        start = Date()
//        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
//        XCTAssert(networkReturnHeaders() == expectedHeaders)
//        delta = start.timeIntervalSinceNow
//        XCTAssert(delta > -5.0)
//    }
}
// TODO
//extension StubTests {
//
//    func isNetworkResultStubbed() -> Bool {
//        expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: app.textViews["result"], handler: nil)
//        waitForExpectations(timeout: 10.0, handler: nil)
//
//        let result = app.textViews["result"].value as! String
//        let resultData = Data(base64Encoded: result)!
//        let resultDict = try! JSONSerialization.jsonObject(with: resultData, options: []) as! [String: Any]
//
//        app.navigationBars.buttons.element(boundBy: 0).tap()
//
//        let networkBase64 = resultDict["data"] as! String
//        if let networkData = Data(base64Encoded: networkBase64) {
//            if let networkJson = try? JSONSerialization.jsonObject(with: networkData, options: []) as! [String: Any] {
//                return (networkJson["stubbed"] != nil)
//            }
//        }
//
//        return false
//    }
//
//    func networkReturnCode() -> Int {
//        expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: app.textViews["result"], handler: nil)
//        waitForExpectations(timeout: 10.0, handler: nil)
//
//        let result = app.textViews["result"].value as! String
//        let resultData = Data(base64Encoded: result)!
//        let resultDict = try! JSONSerialization.jsonObject(with: resultData, options: []) as! [String: Any]
//
//        app.navigationBars.buttons.element(boundBy: 0).tap()
//
//        return (resultDict["responseCode"] as? Int) ?? 0
//    }
//
//    func networkReturnHeaders() -> [String: String] {
//        expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: app.textViews["result"], handler: nil)
//        waitForExpectations(timeout: 10.0, handler: nil)
//
//        let result = app.textViews["result"].value as! String
//        let resultData = Data(base64Encoded: result)!
//        let resultDict = try! JSONSerialization.jsonObject(with: resultData, options: []) as! [String: Any]
//
//        app.navigationBars.buttons.element(boundBy: 0).tap()
//
//        return (resultDict["responseHeaders"] as? [String: String]) ?? [:]
//    }
//}

extension StubTests {
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
