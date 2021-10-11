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

import Foundation
import SBTUITestTunnelClient
import SBTUITestTunnelServer
import XCTest

class StubTests: XCTestCase {
    private let request = NetworkRequests()
    
    func testStubRemoveWithID() {
        let stubId = app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))!
        
        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result, expectedStubValue: 1))
        
        XCTAssert(app.stubRequestsRemove(withId: stubId))
        let result2 = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result2, expectedStubValue: 1))
    }
    
    func testStubRemoveAll() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))
        
        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result, expectedStubValue: 1))
        
        XCTAssert(app.stubRequestsRemoveAll())
        let result2 = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result2, expectedStubValue: 1))
    }
    
    func testStubJSONContentType() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))
        
        let expectedHeaders = ["Content-Type": "application/json"]
        
        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        let headers = result["responseHeaders"] as! [String: String]
        XCTAssert(request.headers(headers, isEqual: expectedHeaders))
    }
    
    func testStubTextContentType() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: "stubbed text"))
        
        let expectedHeaders = ["Content-Type": "text/plain"]
        
        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        let headers = result["responseHeaders"] as! [String: String]
        XCTAssert(request.headers(headers, isEqual: expectedHeaders))
    }
    
    func testStubDataContentType() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: "stubbed data".data(using: .utf8) as Any))
        
        let expectedHeaders = ["Content-Type": "application/octet-stream"]
        
        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        let headers = result["responseHeaders"] as! [String: String]
        XCTAssert(request.headers(headers, isEqual: expectedHeaders))
    }
    
    func testMultipleStubsForSameRequestMatch() {
        XCTContext.runActivity(named: "When adding multiple stubs for the same requests match") { _ in
            app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1], returnCode: 200))
            app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 2], returnCode: 401, activeIterations: 1))
            app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 3], returnCode: 500, activeIterations: 2))
        }
        
        XCTContext.runActivity(named: "They are evaluated in LIFO order and removed when finishing active iterations") { _ in
            let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssert(request.isStubbed(result, expectedStubValue: 3))
            XCTAssertEqual(request.returnCode(result), 500)
            
            let result2 = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssert(request.isStubbed(result2, expectedStubValue: 3))
            XCTAssertEqual(request.returnCode(result2), 500)
            
            let result3 = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssert(request.isStubbed(result3, expectedStubValue: 2))
            XCTAssertEqual(request.returnCode(result3), 401)

            let result4 = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssert(request.isStubbed(result4, expectedStubValue: 1))
            XCTAssertEqual(request.returnCode(result4), 200)
        }
    }
    
    func testStubAddTwiceAndRemovedOnce() {
        let stubId1 = app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1])) ?? ""
        let stubId2 = app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 2])) ?? ""
        
        XCTContext.runActivity(named: "Verify that stubs are evaluated in LIFO order") { _ in
            let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssert(request.isStubbed(result, expectedStubValue: 2))
            app.stubRequestsRemove(withId: stubId2)

            let result2 = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssert(request.isStubbed(result2, expectedStubValue: 1))
            app.stubRequestsRemove(withIds: [stubId1])
            
            let result3 = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssertFalse(request.isStubbed(result3, expectedStubValue: 1))
        }
        
        XCTContext.runActivity(named: "Verify that removing a non active stubId works") { _ in
            app.stubRequestsRemove(withId: stubId1)

            let result4 = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssertFalse(request.isStubbed(result4, expectedStubValue: 1))
        }
    }
    
    func testStubAndRemoveCommand() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1], activeIterations: 2))
        
        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result, expectedStubValue: 1))
        let result2 = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result2, expectedStubValue: 1))
        let result3 = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result3, expectedStubValue: 1))
        
        XCTAssert(app.stubRequestsRemoveAll())
        let result4 = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result4, expectedStubValue: 1))
    }
    
    func testStubDataTask() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))
        
        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result, expectedStubValue: 1))
    }
    
    func testStubUploadDataTask() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))
        
        let result = request.uploadTaskNetwork(urlString: "https://httpbin.org/post", data: "This is a test".data(using: .utf8)!)
        XCTAssert(request.isStubbed(result, expectedStubValue: 1))
    }
    
    func testStubBackgroundUploadDataTask() {
        // background tasks are not managed by the app itself and therefore cannot be stubbed
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))
        
        let data = "This is a test".data(using: .utf8)
        
        let fileName = String(format: "%@_%@", ProcessInfo.processInfo.globallyUniqueString, "file.txt")
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)!
        
        try! data?.write(to: fileURL)
        
        let result = request.backgroundUploadTaskNetwork(urlString: "https://httpbin.org/post", fileUrl: fileURL)
        XCTAssertFalse(request.isStubbed(result, expectedStubValue: 1))
    }
    
    func testStubResponseDelay() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1], responseTime: 5.0))
        
        let start = Date()
        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        let delta = start.timeIntervalSinceNow
        XCTAssert(request.isStubbed(result, expectedStubValue: 1))
        XCTAssert(delta < -5.0 && delta > -8.0)
    }
    
    func testStubResponseCode() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1], returnCode: 401))
        
        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertEqual(request.returnCode(result), 401)
    }
    
    func testStubHeaders() {
        let customHeaders = ["X-Custom": "Custom"]
        let genericReturnString = "Hello world"
        let genericReturnData = genericReturnString.data(using: .utf8)!
        
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: genericReturnData, headers: customHeaders, contentType: "text/plain", returnCode: 200, responseTime: 5.0))
        
        var expectedHeaders = customHeaders
        expectedHeaders["Content-Length"] = String(genericReturnData.count)
        expectedHeaders["Content-Type"] = "text/plain"
        
        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        let headers = result["responseHeaders"] as! [String: String]
        XCTAssert(request.headers(headers, isEqual: expectedHeaders))
    }
    
    func testStubGenericReturnData() {
        let genericReturnString = "Hello world"
        let genericReturnData = genericReturnString.data(using: .utf8)!
        
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: genericReturnData, headers: [:], contentType: "text/plain", returnCode: 200, responseTime: 0.0))
        
        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        
        let networkBase64 = result["data"] as! String
        let networkString = String(data: Data(base64Encoded: networkBase64)!, encoding: .utf8)
        
        XCTAssertEqual(networkString, genericReturnString)
    }
    
    func testStubPostRequest() {
        let stubId1 = app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))!
        let result = request.uploadTaskNetwork(urlString: "https://httpbin.org/post", data: "This is a test".data(using: .utf8)!)
        XCTAssert(request.isStubbed(result, expectedStubValue: 1))
        
        XCTAssert(app.stubRequestsRemove(withId: stubId1))
        let result2 = request.uploadTaskNetwork(urlString: "https://httpbin.org/post", data: "This is a test".data(using: .utf8)!)
        XCTAssertFalse(request.isStubbed(result2, expectedStubValue: 1))
        
        let stubId2 = app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", method: "POST"), response: SBTStubResponse(response: ["stubbed": 1]))!
        let result3 = request.uploadTaskNetwork(urlString: "https://httpbin.org/post", data: "This is a test".data(using: .utf8)!)
        XCTAssert(request.isStubbed(result3, expectedStubValue: 1))
        
        XCTAssert(app.stubRequestsRemove(withId: stubId2))
        let result4 = request.uploadTaskNetwork(urlString: "https://httpbin.org/post", data: "This is a test".data(using: .utf8)!)
        XCTAssertFalse(request.isStubbed(result4, expectedStubValue: 1))
        
        let stubId3 = app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))!
        let result5 = request.uploadTaskNetwork(urlString: "https://httpbin.org/post", data: "This is a test".data(using: .utf8)!)
        XCTAssertFalse(request.isStubbed(result5, expectedStubValue: 1))
        
        XCTAssert(app.stubRequestsRemove(withId: stubId3))
        let result6 = request.uploadTaskNetwork(urlString: "https://httpbin.org/post", data: "This is a test".data(using: .utf8)!)
        XCTAssertFalse(request.isStubbed(result6, expectedStubValue: 1))
    }
    
    func testStubPutRequest() {
        let stubId1 = app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", method: "PUT"), response: SBTStubResponse(response: ["stubbed": 1]))!
        let result = request.uploadTaskNetwork(urlString: "https://httpbin.org/put", data: "This is a test".data(using: .utf8)!, httpMethod: "PUT")
        XCTAssert(request.isStubbed(result, expectedStubValue: 1))
        
        XCTAssert(app.stubRequestsRemove(withId: stubId1))
        let result2 = request.uploadTaskNetwork(urlString: "https://httpbin.org/put", data: "This is a test".data(using: .utf8)!, httpMethod: "PUT")
        XCTAssertFalse(request.isStubbed(result2, expectedStubValue: 1))
        
        let stubId2 = app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", method: "POST"), response: SBTStubResponse(response: ["stubbed": 1]))!
        let result3 = request.uploadTaskNetwork(urlString: "https://httpbin.org/put", data: "This is a test".data(using: .utf8)!, httpMethod: "PUT")
        XCTAssertFalse(request.isStubbed(result3, expectedStubValue: 1))
        
        XCTAssert(app.stubRequestsRemove(withId: stubId2))
        let result4 = request.uploadTaskNetwork(urlString: "https://httpbin.org/put", data: "This is a test".data(using: .utf8)!, httpMethod: "PUT")
        XCTAssertFalse(request.isStubbed(result4, expectedStubValue: 1))
        
        let stubId3 = app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))!
        let result5 = request.uploadTaskNetwork(urlString: "https://httpbin.org/put", data: "This is a test".data(using: .utf8)!, httpMethod: "PUT")
        XCTAssertFalse(request.isStubbed(result5, expectedStubValue: 1))
        
        XCTAssert(app.stubRequestsRemove(withId: stubId3))
        let result6 = request.uploadTaskNetwork(urlString: "https://httpbin.org/put", data: "This is a test".data(using: .utf8)!, httpMethod: "PUT")
        XCTAssertFalse(request.isStubbed(result6, expectedStubValue: 1))
    }
    
    func testStubResponseDefaultOverriders() {
        let contentType = "application/test"
        let responseText = "expected text"
        
        SBTStubResponse.defaultReturnCode = 404
        SBTStubResponse.defaultResponseTime = 5.0
        SBTStubResponse.defaultStringContentType = contentType
        
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: responseText))
        
        var expectedHeaders = [String: String]()
        expectedHeaders["Content-Length"] = String(responseText.count)
        expectedHeaders["Content-Type"] = contentType
        
        var start = Date()
        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        let headers = result["responseHeaders"] as! [String: String]
        XCTAssert(request.headers(headers, isEqual: expectedHeaders))
        XCTAssertEqual(result["responseCode"] as? Int, SBTStubResponse.defaultReturnCode)
        var delta = start.timeIntervalSinceNow
        XCTAssert(delta < -5.0)
        
        SBTStubResponse.resetUnspecifiedDefaults()
        XCTAssert(app.stubRequestsRemoveAll())
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: responseText))
        
        expectedHeaders["Content-Type"] = "text/plain"
        
        start = Date()
        let result2 = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        delta = start.timeIntervalSinceNow
        let headers2 = result2["responseHeaders"] as! [String: String]
        XCTAssert(request.headers(headers2, isEqual: expectedHeaders))
        XCTAssertEqual(result2["responseCode"] as? Int, 200)
        XCTAssert(delta > -5.0)
    }
    
    func testStubRedirection() {
        let redirectionUrl = "https://www.subito.it/"
        app.monitorRequests(matching: SBTRequestMatch(url: redirectionUrl))
        
        let match = SBTRequestMatch(url: "httpbin.org")
        let response = SBTStubResponse(response: "", headers: ["Location": redirectionUrl], contentType: "application/octet-stream", returnCode: 302, responseTime: 0.0)
        app.stubRequests(matching: match, response: response)
        
        let result = request.dataTaskNetworkWithResponse(urlString: "https://httpbin.org", httpMethod: "GET", httpBody: nil, requestHeaders: [:], delay: 0.0)
        
        XCTAssertEqual(result.response.url?.absoluteString, redirectionUrl)
        XCTAssertEqual(result.response.statusCode, 200)
        
        let requests = app.monitoredRequestsFlushAll()
        
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.request?.url?.absoluteString, redirectionUrl)
        XCTAssertEqual(requests.first?.originalRequest?.url?.absoluteString, redirectionUrl)
    }
    
    func testStubRequestHeaders() {
        _ = {
            let match = SBTRequestMatch(url: "httpbin.org", requestHeaders: ["Accept": "gzip.*"])
            let stubId = self.app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
            
            let result = self.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssert(self.request.isStubbed(result, expectedStubValue: 1))
            self.app.stubRequestsRemove(withId: stubId)
        }()
        
        _ = {
            let match = SBTRequestMatch(url: "httpbin.org", requestHeaders: ["Accept": "gzip.*", "Accept-Encoding": "gzip"])
            let stubId = self.app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
            
            let result = self.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssert(self.request.isStubbed(result, expectedStubValue: 1))
            self.app.stubRequestsRemove(withId: stubId)
        }()
        
        _ = {
            let match = SBTRequestMatch(url: "httpbin.org", requestHeaders: ["Accept": "invalid"])
            let stubId = self.app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
            
            let result = self.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssertFalse(self.request.isStubbed(result, expectedStubValue: 1))
            self.app.stubRequestsRemove(withId: stubId)
        }()
        
        _ = {
            let match = SBTRequestMatch(url: "httpbin.org", requestHeaders: ["Invalid": "gzip"])
            let stubId = self.app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
            
            let result = self.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssertFalse(self.request.isStubbed(result, expectedStubValue: 1))
            self.app.stubRequestsRemove(withId: stubId)
        }()
        
        _ = {
            let match = SBTRequestMatch(url: "httpbin.org", requestHeaders: ["Accept": "Invalid", "Accept-Language": "en"])
            let stubId = self.app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
            
            let result = self.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssertFalse(self.request.isStubbed(result, expectedStubValue: 1))
            self.app.stubRequestsRemove(withId: stubId)
        }()
    }
    
    func testStubResponseHeaders() {
        _ = {
            let match = SBTRequestMatch(url: "httpbin.org", responseHeaders: ["Content-Type": "application.*"])
            let stubId = self.app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!

            let result = self.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssert(self.request.isStubbed(result, expectedStubValue: 1))
            self.app.stubRequestsRemove(withId: stubId)
        }()
        
        _ = {
            let match = SBTRequestMatch(url: "httpbin.org", responseHeaders: ["Content-Type": "application.*", "Server": "gunicorn"])
            let stubId = self.app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
            
            let result = self.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssert(self.request.isStubbed(result, expectedStubValue: 1))
            self.app.stubRequestsRemove(withId: stubId)
        }()
        
        _ = {
            let match = SBTRequestMatch(url: "httpbin.org", responseHeaders: ["Content-Type": "invalid"])
            let stubId = self.app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
            
            let result = self.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssertFalse(self.request.isStubbed(result, expectedStubValue: 1))
            self.app.stubRequestsRemove(withId: stubId)
        }()
        
        _ = {
            let match = SBTRequestMatch(url: "httpbin.org", responseHeaders: ["Invalid": "application.*"])
            let stubId = self.app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
            
            let result = self.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssertFalse(self.request.isStubbed(result, expectedStubValue: 1))
            self.app.stubRequestsRemove(withId: stubId)
        }()
        
        _ = {
            let match = SBTRequestMatch(url: "httpbin.org", responseHeaders: ["Content-Type": "application.*", "Server": "invalid"])
            let stubId = self.app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
            
            let result = self.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssertFalse(self.request.isStubbed(result, expectedStubValue: 1))
            self.app.stubRequestsRemove(withId: stubId)
        }()
    }
    
    func testStubRequestAndResponseHeaders() {
        _ = {
            let match = SBTRequestMatch(url: "httpbin.org", requestHeaders: ["Accept": "gzip.*"], responseHeaders: ["Content-Type": "application.*"])
            let stubId = self.app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
            
            let result = self.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssert(self.request.isStubbed(result, expectedStubValue: 1))
            self.app.stubRequestsRemove(withId: stubId)
        }()
        
        _ = {
            let match = SBTRequestMatch(url: "httpbin.org", requestHeaders: ["Accept": "gzip.*", "Accept-Encoding": "gzip"], responseHeaders: ["Content-Type": "application.*", "Server": "gunicorn"])
            let stubId = self.app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
            
            let result = self.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssert(self.request.isStubbed(result, expectedStubValue: 1))
            self.app.stubRequestsRemove(withId: stubId)
        }()
        
        _ = {
            let match = SBTRequestMatch(url: "httpbin.org", requestHeaders: ["Accept": "Invalid"], responseHeaders: ["Content-Type": "application.*"])
            let stubId = self.app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
            
            let result = self.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssertFalse(self.request.isStubbed(result, expectedStubValue: 1))
            self.app.stubRequestsRemove(withId: stubId)
        }()
        
        _ = {
            let match = SBTRequestMatch(url: "httpbin.org", requestHeaders: ["Accept": "gzip.*"], responseHeaders: ["Content-Type": "Invalid"])
            let stubId = self.app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
            
            let result = self.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssertFalse(self.request.isStubbed(result, expectedStubValue: 1))
            self.app.stubRequestsRemove(withId: stubId)
        }()
        
        _ = {
            let match = SBTRequestMatch(url: "httpbin.org", requestHeaders: ["Accept": "Invalid"], responseHeaders: ["Content-Type": "Invalid"])
            let stubId = self.app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
            
            let result = self.request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
            XCTAssertFalse(self.request.isStubbed(result, expectedStubValue: 1))
            self.app.stubRequestsRemove(withId: stubId)
        }()
    }
    
    func testStubAll() {
        let match1 = SBTRequestMatch(url: "httpbin.org")
        let stubId1 = app.stubRequests(matching: match1, response: SBTStubResponse(response: ["stubbed": 1]))!
        
        let stubs1 = app.stubRequestsAll()
        
        XCTAssertEqual(stubs1.count, 1)
        XCTAssertTrue(stubId1.starts(with: "stb-"), "Expecting stub identifier to start with stb-")
        
        let match2 = SBTRequestMatch(url: "httpbin2.org")
        _ = app.stubRequests(matching: match2, response: SBTStubResponse(response: ["stubbed": 1]))!
        
        let stubs2 = app.stubRequestsAll()
        
        XCTAssertEqual(stubs2.count, 2)
        
        app.stubRequestsRemove(withId: stubId1)
        
        let stubs3 = app.stubRequestsAll()
        
        XCTAssertEqual(stubs3.count, 1)
        
        app.stubRequestsRemoveAll()
        
        let stubs4 = app.stubRequestsAll()
        
        XCTAssertEqual(stubs4.count, 0)
    }
    
    func testStubActiveCount() {
        let match1 = SBTRequestMatch(url: "httpbin.org", method: "GET")
        _ = app.stubRequests(matching: match1, response: SBTStubResponse(response: ["stubbed": 1], activeIterations: 2))!
        let match2 = SBTRequestMatch(url: "httpbin.org", method: "POST")
        _ = app.stubRequests(matching: match2, response: SBTStubResponse(response: ["stubbed": 1]))!
        
        let stubs1 = app.stubRequestsAll()
        
        XCTAssertEqual(stubs1[match1]?.activeIterations, 2)
        XCTAssertEqual(stubs1[match2]?.activeIterations, 0)
        
        let result1 = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result1, expectedStubValue: 1))
        
        let stubs2 = app.stubRequestsAll()
        
        XCTAssertEqual(stubs2[match1]?.activeIterations, 1)
        XCTAssertEqual(stubs2[match2]?.activeIterations, 0)
        
        let result2 = request.dataTaskNetwork(urlString: "https://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result2, expectedStubValue: 1))
        
        let stubs3 = app.stubRequestsAll()
        
        XCTAssertNil(stubs3[match1])
        XCTAssertEqual(stubs2[match2]?.activeIterations, 0)
        
        let result3 = request.uploadTaskNetwork(urlString: "https://httpbin.org/post", data: "This is a test".data(using: .utf8)!)
        XCTAssert(request.isStubbed(result3, expectedStubValue: 1))
        
        let stubs4 = app.stubRequestsAll()
        
        XCTAssertEqual(stubs4[match2]?.activeIterations, 0)
        
        let result4 = request.uploadTaskNetwork(urlString: "https://httpbin.org/post", data: "This is a test".data(using: .utf8)!)
        XCTAssert(request.isStubbed(result4, expectedStubValue: 1))
        
        let stubs5 = app.stubRequestsAll()
        
        XCTAssertEqual(stubs5[match2]?.activeIterations, 0)
    }
    
    func testStubActiveCountRemoving() {
        let match1 = SBTRequestMatch(url: "httpbin.org", method: "GET")
        let stubId1 = app.stubRequests(matching: match1, response: SBTStubResponse(response: ["stubbed": 1], activeIterations: 2))!
        let match2 = SBTRequestMatch(url: "httpbin.org", method: "POST")
        let stubId2 = app.stubRequests(matching: match2, response: SBTStubResponse(response: ["stubbed": 1]))!
        
        let stubs1 = app.stubRequestsAll()
        
        XCTAssertEqual(stubs1[match1]?.activeIterations, 2)
        XCTAssertEqual(stubs1[match2]?.activeIterations, 0)
        
        app.stubRequestsRemove(withId: stubId1)
        
        let stubs2 = app.stubRequestsAll()
        
        XCTAssertNil(stubs2[match1])
        XCTAssertEqual(stubs2[match2]?.activeIterations, 0)
        
        app.stubRequestsRemove(withId: stubId2)
        
        let stubs3 = app.stubRequestsAll()
        
        XCTAssertNil(stubs3[match1])
        XCTAssertNil(stubs3[match2])
    }
    
    func testStubActiveCountRemovingAll() {
        let match1 = SBTRequestMatch(url: "httpbin.org", method: "GET")
        _ = app.stubRequests(matching: match1, response: SBTStubResponse(response: ["stubbed": 1], activeIterations: 2))!
        let match2 = SBTRequestMatch(url: "httpbin.org", method: "POST")
        _ = app.stubRequests(matching: match2, response: SBTStubResponse(response: ["stubbed": 1]))!
        
        let stubs1 = app.stubRequestsAll()
        
        XCTAssertEqual(stubs1[match1]?.activeIterations, 2)
        XCTAssertEqual(stubs1[match2]?.activeIterations, 0)
        
        app.stubRequestsRemoveAll()
        
        let stubs2 = app.stubRequestsAll()
        
        XCTAssertNil(stubs2[match1])
        XCTAssertNil(stubs2[match2])
    }
    
    func testStubPostWithQueryRequest() {
        XCTContext.runActivity(named: "Test POST stubbing with only body succeeds") { _ in
            let match = SBTRequestMatch(url: "httpbin.org", method: "POST", body: "is a test")
            _ = app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
            
            let result = request.uploadTaskNetwork(urlString: "https://httpbin.org/post", data: "This is a test".data(using: .utf8)!)
            XCTAssert(request.isStubbed(result, expectedStubValue: 1))
            XCTAssert(app.stubRequestsRemoveAll())
        }
        
        XCTContext.runActivity(named: "Test POST stubbing with body and query succeeds") { _ in
            let match = SBTRequestMatch(url: "httpbin.org", query: ["&param1=val1"], method: "POST", body: "is a test")
            _ = app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
                        
            let result = request.uploadTaskNetwork(urlString: "https://httpbin.org/post?param1=val1", data: "This is a test".data(using: .utf8)!)
            XCTAssert(request.isStubbed(result, expectedStubValue: 1))
            XCTAssert(app.stubRequestsRemoveAll())
        }
        
        XCTContext.runActivity(named: "Test POST stubbing with body and query fails") { _ in
            let match = SBTRequestMatch(url: "httpbin.org", query: ["&param1=val1"], method: "POST", body: "is a test")
            _ = app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
                        
            let result = request.uploadTaskNetwork(urlString: "https://httpbin.org/post", data: "This is a test".data(using: .utf8)!)
            XCTAssertFalse(request.isStubbed(result, expectedStubValue: 1))
            XCTAssert(app.stubRequestsRemoveAll())
        }
        
        XCTContext.runActivity(named: "Test POST stubbing with body and query fails") { _ in
            let match = SBTRequestMatch(url: "httpbin.org", query: ["&param1=val2"], method: "POST", body: "is a test")
            _ = app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
                        
            let result = request.uploadTaskNetwork(urlString: "https://httpbin.org/post?param1=val1", data: "This is a test".data(using: .utf8)!)
            XCTAssertFalse(request.isStubbed(result, expectedStubValue: 1))
            XCTAssert(app.stubRequestsRemoveAll())
        }
        
        XCTContext.runActivity(named: "Test POST stubbing with body and query fails") { _ in
            let match = SBTRequestMatch(url: "httpbin.org", query: ["&param1=val1"], method: "POST", body: "is a test")
            _ = app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
                        
            let result = request.uploadTaskNetwork(urlString: "https://httpbin.org/post?param1=val1", data: "This is not a test".data(using: .utf8)!)
            XCTAssertFalse(request.isStubbed(result, expectedStubValue: 1))
            XCTAssert(app.stubRequestsRemoveAll())
        }
        
        XCTContext.runActivity(named: "Test POST stubbing with body and query fails") { _ in
            let match = SBTRequestMatch(url: "httpbin.org", query: ["&param1=val1"], method: "POST", body: "is a test")
            _ = app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
                        
            let result = request.downloadTaskNetwork(urlString: "https://httpbin.org/get?param1=val1", data: "This is not a test".data(using: .utf8)!, httpMethod: "GET")
            XCTAssertFalse(request.isStubbed(result, expectedStubValue: 1))
            XCTAssert(app.stubRequestsRemoveAll())
        }
        
        XCTContext.runActivity(named: "Test POST stubbing with query matching body #1 fails") { _ in
            let match = SBTRequestMatch(url: "httpbin.org", query: ["&param6=val6&param5=val5"], method: "POST")
            app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))
            
            let result = request.dataTaskNetwork(urlString: "https://httpbin.org/post", httpMethod: "POST", httpBody: "&param5=val5&param6=val6")
            XCTAssertFalse(request.isStubbed(result, expectedStubValue: 1))
            XCTAssert(app.stubRequestsRemoveAll())
        }

        XCTContext.runActivity(named: "Test POST stubbing with query matching body #2 fails") { _ in
            let match = SBTRequestMatch(url: "httpbin.org", query: ["&param5=val5", "&param1=val1"], method: "POST")
            app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))
            
            let result = request.dataTaskNetwork(urlString: "https://httpbin.org/post", httpMethod: "POST", httpBody: "&param5=val5&param6=val6")
            XCTAssertFalse(request.isStubbed(result, expectedStubValue: 1))
            XCTAssert(app.stubRequestsRemoveAll())
        }

        XCTContext.runActivity(named: "Test GET stubbing with query matching body #3 fails") { _ in
            let match = SBTRequestMatch(url: "httpbin.org", query: ["&param5=val5", "&param6=val6"], method: "GET")
            app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))
            
            let result = request.dataTaskNetwork(urlString: "https://httpbin.org/post", httpMethod: "POST", httpBody: "&param5=val5&param6=val6")
            XCTAssertFalse(request.isStubbed(result, expectedStubValue: 1))
            XCTAssert(app.stubRequestsRemoveAll())
        }
    }
    
    func testStubGetWithQueryRequest() {
        XCTContext.runActivity(named: "Test GET stubbing with only body succeeds") { _ in
            let match = SBTRequestMatch(url: "httpbin.org", method: "GET", body: "is a test")
            _ = app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
            
            let result = request.downloadTaskNetwork(urlString: "https://httpbin.org/get", data: "This is a test".data(using: .utf8)!, httpMethod: "GET")
            XCTAssert(request.isStubbed(result, expectedStubValue: 1))
        }
        
        XCTAssert(app.stubRequestsRemoveAll())
        
        XCTContext.runActivity(named: "Test GET stubbing with body and query succeeds") { _ in
            let match = SBTRequestMatch(url: "httpbin.org", query: ["&param1=val1"], method: "GET", body: "is a test")
            _ = app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
                        
            let result = request.downloadTaskNetwork(urlString: "https://httpbin.org/get?param1=val1", data: "This is a test".data(using: .utf8)!, httpMethod: "GET")
            XCTAssert(request.isStubbed(result, expectedStubValue: 1))
        }
        
        XCTAssert(app.stubRequestsRemoveAll())
        
        XCTContext.runActivity(named: "Test GET stubbing with body and query fails") { _ in
            let match = SBTRequestMatch(url: "httpbin.org", query: ["&param1=val1"], method: "GET", body: "is a test")
            _ = app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
                        
            let result = request.downloadTaskNetwork(urlString: "https://httpbin.org/get", data: "This is a test".data(using: .utf8)!, httpMethod: "GET")
            XCTAssertFalse(request.isStubbed(result, expectedStubValue: 1))
        }
        
        XCTAssert(app.stubRequestsRemoveAll())
        
        XCTContext.runActivity(named: "Test GET stubbing with body and query fails") { _ in
            let match = SBTRequestMatch(url: "httpbin.org", query: ["&param1=val2"], method: "GET", body: "is a test")
            _ = app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
                        
            let result = request.downloadTaskNetwork(urlString: "https://httpbin.org/get?param1=val1", data: "This is a test".data(using: .utf8)!, httpMethod: "GET")
            XCTAssertFalse(request.isStubbed(result, expectedStubValue: 1))
        }
        
        XCTAssert(app.stubRequestsRemoveAll())
        
        XCTContext.runActivity(named: "Test GET stubbing with body and query fails") { _ in
            let match = SBTRequestMatch(url: "httpbin.org", query: ["&param1=val1"], method: "GET", body: "is a test")
            _ = app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
                        
            let result = request.downloadTaskNetwork(urlString: "https://httpbin.org/get?param1=val1", data: "This is not a test".data(using: .utf8)!, httpMethod: "GET")
            XCTAssertFalse(request.isStubbed(result, expectedStubValue: 1))
        }
        
        XCTAssert(app.stubRequestsRemoveAll())
        
        XCTContext.runActivity(named: "Test GET stubbing with body and query fails") { _ in
            let match = SBTRequestMatch(url: "httpbin.org", query: ["&param1=val1"], method: "GET", body: "is a test")
            _ = app.stubRequests(matching: match, response: SBTStubResponse(response: ["stubbed": 1]))!
                        
            let result = request.uploadTaskNetwork(urlString: "https://httpbin.org/post?param1=val1", data: "This is not a test".data(using: .utf8)!, httpMethod: "POST")
            XCTAssertFalse(request.isStubbed(result, expectedStubValue: 1))
        }
    }
    
    func testStubFailure() {
        XCTContext.runActivity(named: "Test GET stubbing fails") { _ in
            let match = SBTRequestMatch(url: "httpbin.org", method: "GET", body: "is a test")
            _ = app.stubRequests(matching: match, response: SBTStubFailureResponse(errorCode: URLError.notConnectedToInternet.rawValue))
            
            let result = request.downloadTaskNetwork(urlString: "https://httpbin.org/get", data: "This is a test".data(using: .utf8)!, httpMethod: "GET")
            XCTAssert(request.isNotConnectedError(result))
        }
    }
}

extension StubTests {
    override func setUp() {
        SBTUITestTunnelServer.perform(NSSelectorFromString("_connectionlessReset"))
        app.launchConnectionless { (path, params) -> String in
            SBTUITestTunnelServer.performCommand(path, params: params)
        }
    }
}
