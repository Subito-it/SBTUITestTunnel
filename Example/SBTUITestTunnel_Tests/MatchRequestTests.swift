// MatchRequestTests.swift
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

class MatchRequestTests: XCTestCase {
    private let request = NetworkRequests()
    
    func testSimpleUrlAllMethods() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org"), response: SBTStubResponse(response: ["stubbed": 1]))
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result))
        
        let result2 = request.dataTaskNetwork(urlString: "http://httpbin.org/post", httpMethod: "POST", httpBody: "&param5=val5&param6=val6")
        XCTAssert(request.isStubbed(result2))
    }
    
    func testSimpleUrlGetOnly() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result))
        
        let result2 = request.dataTaskNetwork(urlString: "http://httpbin.org/post", httpMethod: "POST", httpBody: "&param5=val5&param6=val6")
        XCTAssertFalse(request.isStubbed(result2))
    }
    
    func testUrlWithQueryGetOnly() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", query: ["&param1=val1", "&param2=val2"], method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result))
        XCTAssert(app.stubRequestsRemoveAll())
        
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", query: ["&param2=val2", "&param1=val1"], method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))
        let result2 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result2))
        XCTAssert(app.stubRequestsRemoveAll())
        
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", query: ["&param1=val1&param2=val2"], method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))
        let result3 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result3))
        XCTAssert(app.stubRequestsRemoveAll())
        
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", query: ["&param2=val2&param1=val1"], method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))
        let result4 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result4))
        XCTAssert(app.stubRequestsRemoveAll())
        
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", query: ["&param1=val1", "&param3=val3"], method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))
        let result5 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result5))
        XCTAssert(app.stubRequestsRemoveAll())
        
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", query: ["&param1=val1", "&param2=val2"], method: "POST"), response: SBTStubResponse(response: ["stubbed": 1]))
        let result6 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result6))
        XCTAssert(app.stubRequestsRemoveAll())
    }
    
    func testPostWithBody() {
        let requestMatch = SBTRequestMatch(url: "httpbin.org", query: [], method: "POST", body: "QueryName")
        app.stubRequests(matching: requestMatch, response: SBTStubResponse(response: ["stubbed": 1]))
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org", httpMethod: "POST", httpBody: "query QueryName")
        XCTAssert(request.isStubbed(result))
    }
    
    func testPostWithJsonBody() {
        let requestMatch = SBTRequestMatch(url: "httpbin.org", query: [], method: "POST", body: #"\{ "key": "value" \}"#)
        app.stubRequests(matching: requestMatch, response: SBTStubResponse(response: ["stubbed": 1]))
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org", httpMethod: "POST", httpBody: #"{ "key": "value" }"#)
        XCTAssert(request.isStubbed(result))
    }
    
    func testPostWithBodyInverted() {
        let requestMatchInverted = SBTRequestMatch(url: "httpbin.org", query: [], method: "POST", body: "!QueryName")
        app.stubRequests(matching: requestMatchInverted, response: SBTStubResponse(response: ["stubbed": 1]))
        
        let containingBodyMatch = request.dataTaskNetwork(urlString: "http://httpbin.org", httpMethod: "POST", httpBody: "query QueryName")
        XCTAssertFalse(request.isStubbed(containingBodyMatch))
        
        let notContainingBodyMatch = request.dataTaskNetwork(urlString: "http://httpbin.org", httpMethod: "POST", httpBody: "query AnotherQuery")
        XCTAssert(request.isStubbed(notContainingBodyMatch))
    }
    
    func testMethodHonored() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org/post", method: "POST"), response: SBTStubResponse(response: ["stubbed": 1]))
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/post", httpMethod: "POST", httpBody: "&param5=val5&param6=val6")
        XCTAssert(request.isStubbed(result))
        XCTAssert(app.stubRequestsRemoveAll())
        
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org/post", method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))
        let result2 = request.dataTaskNetwork(urlString: "http://httpbin.org/post", httpMethod: "POST", httpBody: "&param5=val5&param6=val6")
        XCTAssertFalse(request.isStubbed(result2))
        XCTAssert(app.stubRequestsRemoveAll())
    }
        
    func testInvertQueryGetOnly() {
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", query: ["!param1=val1", "&param2=val2"], method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result))
        XCTAssert(app.stubRequestsRemoveAll())
        
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", query: ["&param1=val1", "!param2=val2"], method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))
        let result2 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result2))
        XCTAssert(app.stubRequestsRemoveAll())
        
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", query: ["!param1=val1", "!param2=val2"], method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))
        let result3 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result3))
        XCTAssert(app.stubRequestsRemoveAll())
        
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", query: ["!param9=val9", "&param1=val1"], method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))
        let result4 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result4))
        XCTAssert(app.stubRequestsRemoveAll())
        
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", query: ["&param1=val1", "!param9=val9"], method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))
        let result5 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result5))
        XCTAssert(app.stubRequestsRemoveAll())
        
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", query: ["&param1=val1", "&param2=val2", "!param9=val9"], method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))
        let result6 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result6))
        XCTAssert(app.stubRequestsRemoveAll())
        
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", query: ["&param1=val1", "!param9=val9", "&param2=val2"], method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))
        let result7 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result7))
        XCTAssert(app.stubRequestsRemoveAll())
        
        app.stubRequests(matching: SBTRequestMatch(url: "httpbin.org", query: ["!param9=val9", "&param1=val1", "&param2=val2"], method: "GET"), response: SBTStubResponse(response: ["stubbed": 1]))
        let result8 = request.dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result8))
        XCTAssert(app.stubRequestsRemoveAll())
    }
}

extension MatchRequestTests {
    override func setUp() {
        app.launchConnectionless { (path, params) -> String in
            SBTUITestTunnelServer.performCommand(path, params: params)
        }
    }
}
