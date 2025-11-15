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
        let stubId = app.stubRequests(matching: SBTRequestMatch(url: "postman-echo.com"), response: SBTStubResponse(response: ["stubbed": 1]))!

        let result = request.dataTaskNetwork(urlString: "https://postman-echo.com/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result, expectedStubValue: 1))

        XCTAssert(app.stubRequestsRemove(id: stubId))
        let result2 = request.dataTaskNetwork(urlString: "https://postman-echo.com/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result2, expectedStubValue: 1))
    }

    func testStubRemoveAll() {
        app.stubRequests(matching: SBTRequestMatch(url: "postman-echo.com"), response: SBTStubResponse(response: ["stubbed": 1]))

        let result = request.dataTaskNetwork(urlString: "https://postman-echo.com/get?param1=val1&param2=val2")
        XCTAssert(request.isStubbed(result, expectedStubValue: 1))

        XCTAssert(app.stubRequestsRemoveAll())
        let result2 = request.dataTaskNetwork(urlString: "https://postman-echo.com/get?param1=val1&param2=val2")
        XCTAssertFalse(request.isStubbed(result2, expectedStubValue: 1))
    }

    func testStubJSONContentType() {
        app.stubRequests(matching: SBTRequestMatch(url: "postman-echo.com"), response: SBTStubResponse(response: ["stubbed": 1]))

        let expectedHeaders = ["Content-Type": "application/json"]

        let result = request.dataTaskNetwork(urlString: "https://postman-echo.com/get?param1=val1&param2=val2")
        let headers = result["responseHeaders"] as! [String: String]
        XCTAssert(request.headers(headers, isEqual: expectedHeaders))
    }

    func testStubPKPassContentType() {
        app.stubRequests(matching: SBTRequestMatch(url: "postman-echo.com"), response: SBTStubResponse(fileNamed: "test_file.pkpass"))

        let expectedHeaders = ["Content-Type": "application/vnd.apple.pkpass"]

        let result = request.dataTaskNetwork(urlString: "https://postman-echo.com/get?param1=val1&param2=val2")
        let headers = result["responseHeaders"] as! [String: String]
        XCTAssert(request.headers(headers, isEqual: expectedHeaders))
    }

    func testMultipleStubsForSameRequestMatch() {
        XCTContext.runActivity(named: "When adding multiple stubs for the same requests match") { _ in
            app.stubRequests(matching: SBTRequestMatch(url: "postman-echo.com"), response: SBTStubResponse(response: ["stubbed": 1], returnCode: 200))
            app.stubRequests(matching: SBTRequestMatch(url: "postman-echo.com"), response: SBTStubResponse(response: ["stubbed": 2], returnCode: 401, activeIterations: 1))
            app.stubRequests(matching: SBTRequestMatch(url: "postman-echo.com"), response: SBTStubResponse(response: ["stubbed": 3], returnCode: 500, activeIterations: 2))
        }

        XCTContext.runActivity(named: "They are evaluated in LIFO order and removed when finishing active iterations") { _ in
            let result = request.dataTaskNetwork(urlString: "https://postman-echo.com/get?param1=val1&param2=val2")
            XCTAssert(request.isStubbed(result, expectedStubValue: 3))
            XCTAssertEqual(request.returnCode(result), 500)

            let result2 = request.dataTaskNetwork(urlString: "https://postman-echo.com/get?param1=val1&param2=val2")
            XCTAssert(request.isStubbed(result2, expectedStubValue: 3))
            XCTAssertEqual(request.returnCode(result2), 500)

            let result3 = request.dataTaskNetwork(urlString: "https://postman-echo.com/get?param1=val1&param2=val2")
            XCTAssert(request.isStubbed(result3, expectedStubValue: 2))
            XCTAssertEqual(request.returnCode(result3), 401)

            let result4 = request.dataTaskNetwork(urlString: "https://postman-echo.com/get?param1=val1&param2=val2")
            XCTAssert(request.isStubbed(result4, expectedStubValue: 1))
            XCTAssertEqual(request.returnCode(result4), 200)
        }
    }
}
