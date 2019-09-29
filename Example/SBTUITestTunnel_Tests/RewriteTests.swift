// RewriteTests.swift
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

class RewriteTests: XCTestCase {
    
    private let request = NetworkRequests()
    
    func testURLRewrite() {
        let requestMatch = SBTRequestMatch(url: "httpbin.org")

        let rewrite = SBTRewrite(requestUrlReplacement: [SBTRewriteReplacement(find: "param2=val2", replace: "param2a=val2a"),
                                                         SBTRewriteReplacement(find: "param1=val1", replace: "param1a=val1a")])

        app.rewriteRequests(matching: requestMatch, rewrite: rewrite)

        let result = request.dataTaskNetworkWithResponse(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        
        XCTAssertEqual(result.response.url?.absoluteString, "http://httpbin.org/get?param1a=val1a&param2a=val2a")
    }

    func testURLRewriteAndThrottle() {
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        
        let rewrite = SBTRewrite(requestUrlReplacement: [SBTRewriteReplacement(find: "param2=val2", replace: "param2a=val2a"),
                                                         SBTRewriteReplacement(find: "param1=val1", replace: "param1a=val1a")])
        
        app.rewriteRequests(matching: requestMatch, rewrite: rewrite)
        app.throttleRequests(matching: requestMatch, responseTime: 5.0)
        
        let start = Date()
        let result = request.dataTaskNetworkWithResponse(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        let delta = start.timeIntervalSinceNow
        
        XCTAssert(delta < -5.0, "Got \(delta)")
        XCTAssertEqual(result.response.url?.absoluteString, "http://httpbin.org/get?param1a=val1a&param2a=val2a")
    }
    
    func testURLRewriteAndThrottleAndMonitor() {
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        
        let rewrite = SBTRewrite(requestUrlReplacement: [SBTRewriteReplacement(find: "param2=val2", replace: "param2a=val2a"),
                                                         SBTRewriteReplacement(find: "param1=val1", replace: "param1a=val1a")])
        
        app.rewriteRequests(matching: requestMatch, rewrite: rewrite)
        app.throttleRequests(matching: requestMatch, responseTime: 5.0)
        app.monitorRequests(matching: requestMatch)
        
        let start = Date()
        let result = request.dataTaskNetworkWithResponse(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        let delta = start.timeIntervalSinceNow
        
        let monitoredRequests = app.monitoredRequestsFlushAll()
        
        XCTAssertEqual(monitoredRequests.count, 1)
        XCTAssertEqual(monitoredRequests.first?.request?.url?.absoluteString, "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertEqual(monitoredRequests.first?.isRewritten, true)
        XCTAssertEqual(monitoredRequests.first?.response?.url?.absoluteString, "http://httpbin.org/get?param1a=val1a&param2a=val2a")
        XCTAssert(delta < -5.0)
        XCTAssertEqual(result.response.url?.absoluteString, "http://httpbin.org/get?param1a=val1a&param2a=val2a")
    }
    
    func testURLRewriteAndMonitorAndThrottle() {
        // change the order of app.requests
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        
        let rewrite = SBTRewrite(requestUrlReplacement: [SBTRewriteReplacement(find: "param2=val2", replace: "param2a=val2a"),
                                                         SBTRewriteReplacement(find: "param1=val1", replace: "param1a=val1a")])
        
        app.rewriteRequests(matching: requestMatch, rewrite: rewrite)
        app.monitorRequests(matching: requestMatch)
        app.throttleRequests(matching: requestMatch, responseTime: 5.0)
        
        let start = Date()
        let result = request.dataTaskNetworkWithResponse(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        let delta = start.timeIntervalSinceNow
        
        let monitoredRequests = app.monitoredRequestsFlushAll()
        
        XCTAssertEqual(monitoredRequests.count, 1)
        XCTAssertEqual(monitoredRequests.first?.request?.url?.absoluteString, "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertEqual(monitoredRequests.first?.isRewritten, true)
        XCTAssertEqual(monitoredRequests.first?.response?.url?.absoluteString, "http://httpbin.org/get?param1a=val1a&param2a=val2a")
        XCTAssert(delta < -5.0)
        XCTAssertEqual(result.response.url?.absoluteString, "http://httpbin.org/get?param1a=val1a&param2a=val2a")
    }
    
    func testURLRewriteAndRemove() {
        // change the order of app.requests
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        
        let rewrite = SBTRewrite(requestUrlReplacement: [SBTRewriteReplacement(find: "param2=val2", replace: "param2a=val2a"),
                                                         SBTRewriteReplacement(find: "param1=val1", replace: "param1a=val1a")])
        
        app.rewriteRequests(matching: requestMatch, rewrite: rewrite, removeAfterIterations: 1)
        
        let result = request.dataTaskNetworkWithResponse(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertEqual(result.response.url?.absoluteString, "http://httpbin.org/get?param1a=val1a&param2a=val2a")

        let result2 = request.dataTaskNetworkWithResponse(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertEqual(result2.response.url?.absoluteString, "http://httpbin.org/get?param1=val1&param2=val2")
    }

    func testURLRewriteAndRemoveSpecific() {
        // change the order of app.requests
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        
        let rewrite = SBTRewrite(requestUrlReplacement: [SBTRewriteReplacement(find: "param2=val2", replace: "param2a=val2a"),
                                                         SBTRewriteReplacement(find: "param1=val1", replace: "param1a=val1a")])
        
        let requestId = app.rewriteRequests(matching: requestMatch, rewrite: rewrite) ?? ""
        
        let result = request.dataTaskNetworkWithResponse(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertEqual(result.response.url?.absoluteString, "http://httpbin.org/get?param1a=val1a&param2a=val2a")
        XCTAssert(app.rewriteRequestsRemove(withId: requestId))
        let result2 = request.dataTaskNetworkWithResponse(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertEqual(result2.response.url?.absoluteString, "http://httpbin.org/get?param1=val1&param2=val2")
    }
    
    func testURLRewriteAndRemoveAll() {
        // change the order of app.requests
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        
        let rewrite = SBTRewrite(requestUrlReplacement: [SBTRewriteReplacement(find: "param2=val2", replace: "param2a=val2a"),
                                                         SBTRewriteReplacement(find: "param1=val1", replace: "param1a=val1a")])
        
        app.rewriteRequests(matching: requestMatch, rewrite: rewrite)
        
        let result = request.dataTaskNetworkWithResponse(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertEqual(result.response.url?.absoluteString, "http://httpbin.org/get?param1a=val1a&param2a=val2a")
        XCTAssert(app.rewriteRequestsRemoveAll())
        let result2 = request.dataTaskNetworkWithResponse(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertEqual(result2.response.url?.absoluteString, "http://httpbin.org/get?param1=val1&param2=val2")
    }

    func testRequestBodyRewrite() {
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        
        let rewrite = SBTRewrite(requestReplacement: [SBTRewriteReplacement(find: "param2_val2", replace: "param2a_val2a"),
                                                      SBTRewriteReplacement(find: "param1_val1", replace: "param1a_val1a")])
        
        app.rewriteRequests(matching: requestMatch, rewrite: rewrite)
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/post", httpMethod: "POST", httpBody: "This is a test where I want to replace param2_val2 and param1_val1")

        
        let networkBase64 = result["data"] as! String
        let networkData = Data(base64Encoded: networkBase64)!
        let postDict = ((try? JSONSerialization.jsonObject(with: networkData, options: [])) as? [String: Any]) ?? [:]
        let postContent = (postDict["form"] as! [String: Any]).keys.first ?? ""
        
        XCTAssertEqual(postContent, "This is a test where I want to replace param2a_val2a and param1a_val1a")
    }
    
    func testRequestHeaderRewrite() {
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        
        let rewrite = SBTRewrite(requestHeadersReplacement: ["param1": "val1a", "param2": "val2a", "param3": "newVal", "Accept-Language": "it-it", "remove_param": ""])

        app.rewriteRequests(matching: requestMatch, rewrite: rewrite)

        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get", requestHeaders: ["param1": "val1", "param2": "val2", "remove_param": "value"])

        let networkBase64 = result["data"] as! String
        let networkData = Data(base64Encoded: networkBase64)!
        let dict = ((try? JSONSerialization.jsonObject(with: networkData, options: [])) as? [String: Any]) ?? [:]
        let headers = dict["headers"] as! [String: Any]
        
        XCTAssertEqual(headers["Param1"] as? String, "val1a")
        XCTAssertEqual(headers["Param2"] as? String, "val2a")
        XCTAssertEqual(headers["Param3"] as? String, "newVal")
        XCTAssertEqual(headers["Accept-Language"] as? String, "it-it")
        XCTAssertFalse(headers.keys.contains("remove_param"))
    }

    func testResponseBodyRewrite() {
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        
        let rewrite = SBTRewrite(responseReplacement: [SBTRewriteReplacement(find: "httpbin.org", replace: "myserver.com"),
                                                       SBTRewriteReplacement(find: "Accept-Language", replace: "Accept-Language222")])

        app.rewriteRequests(matching: requestMatch, rewrite: rewrite)
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/gzip")
        
        let networkBase64 = result["data"] as! String
        let networkData = Data(base64Encoded: networkBase64)!
        let dict = ((try? JSONSerialization.jsonObject(with: networkData, options: [])) as? [String: Any]) ?? [:]
    
        let rewrittenBody = dict["headers"] as! [String: String]
        
        XCTAssert(rewrittenBody.keys.contains("Accept-Language222"))
        XCTAssertEqual(rewrittenBody["Host"], "myserver.com")
    }
    
    func testResponseHeaderRewrite() {
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        
        let rewrite = SBTRewrite(responseHeadersReplacement: ["param1": "val1a", "param2": "val2a", "param3": "", "param4": "val4"])
        
        app.rewriteRequests(matching: requestMatch, rewrite: rewrite)
        
        let result = request.dataTaskNetworkWithResponse(urlString: "http://httpbin.org/response-headers?param1=val1&param2=val2&param3=val3")
        
        let headers = result.headers
        
        XCTAssertEqual(headers["param1"], "val1a")
        XCTAssertEqual(headers["param2"], "val2a")
        XCTAssertEqual(headers["param4"], "val4")
        XCTAssertFalse(headers.keys.contains("param3"))
    }

    func testResponseStatusCodeRewrite() {
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        
        let statusCode = 201
        
        let rewrite = SBTRewrite(responseStatusCode: statusCode)
        
        app.rewriteRequests(matching: requestMatch, rewrite: rewrite)
        
        let result = request.dataTaskNetworkWithResponse(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertEqual(result.response.statusCode, statusCode)
    }
}

extension RewriteTests {
    override func setUp() {
        app.launchConnectionless { (path, params) -> String in
            return SBTUITestTunnelServer.performCommand(path, params: params)
        }
    }
}
