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

import SBTUITestTunnel
import Foundation

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
        
        XCTAssert(delta < -5.0)
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
        XCTAssertEqual(monitoredRequests.first?.request?.url?.absoluteString, "http://httpbin.org/get?param1a=val1a&param2a=val2a")
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
        XCTAssertEqual(monitoredRequests.first?.request?.url?.absoluteString, "http://httpbin.org/get?param1a=val1a&param2a=val2a")
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
        
        let rewrite = SBTRewrite(requestUrlReplacement: [SBTRewriteReplacement(find: "param2=val2", replace: "param2a=val2a"),
                                                         SBTRewriteReplacement(find: "param1=val1", replace: "param1a=val1a")])
        
        app.rewriteRequests(matching: requestMatch, rewrite: rewrite)
        let result = request.dataTaskNetworkWithResponse(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        
        
        

//        let rewrittenResponse = SBTRewrite(request: [SBTRewriteReplacement(find: "param.*\"", replace: ""),
//                                                     SBTRewriteReplacement(find: "\"val.*", replace: "")],
//                                           headers: [:])
//        app.rewriteRequests(matching: requestMatch, rewrite: rewrite)
        

        
// TODO
    }
    
    func testRequestHeaderRewrite() {
// TODO
    }

    func testResponseBodyRewrite() {
    }
    
    func testResponseHeaderRewrite() {
        // TODO
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
