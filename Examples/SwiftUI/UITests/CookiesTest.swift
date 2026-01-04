// CookiesTest.swift
//
// Copyright (C) 2025 Subito.it S.r.l (www.subito.it)
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

class CookiesTest: XCTestCase {
    private let request = NetworkRequests()

    private func countCookies() -> Int {
        let result = request.dataTaskNetwork(urlString: "https://postman-echo.com/cookies")
        let json = request.json(result)

        var cookies = json["cookies"] as? [String: Any] ?? [:]
        cookies = cookies.filter { $0.key.hasPrefix("_") == false }

        return cookies.keys.count
    }

    func testCookiesGetBlocked() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        _ = request.dataTaskNetwork(urlString: "https://postman-echo.com/cookies/set?name=value") // set a random cookie

        let requestMatch = SBTRequestMatch(url: "postman-echo.com")
        app.blockCookiesInRequests(matching: requestMatch)

        XCTAssertEqual(countCookies(), 0)
    }

    func testBlockCookiesAndRemove() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        _ = request.dataTaskNetwork(urlString: "https://postman-echo.com/cookies/set?name=value") // set a random cookie

        let requestMatch = SBTRequestMatch(url: "postman-echo.com")
        app.blockCookiesInRequests(matching: requestMatch, activeIterations: 1)
        XCTAssertEqual(countCookies(), 0)
        XCTAssertEqual(countCookies(), 1)
    }

    func testBlockCookiesAndRemoveAll() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        _ = request.dataTaskNetwork(urlString: "https://postman-echo.com/cookies/set?name=value") // set a random cookie

        let requestMatch = SBTRequestMatch(url: "postman-echo.com")
        app.blockCookiesInRequests(matching: requestMatch)
        XCTAssertEqual(countCookies(), 0)
        XCTAssert(app.blockCookiesRequestsRemoveAll())
        XCTAssertEqual(countCookies(), 1)
    }

    func testBlockCookiesAndRemoveSpecific() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        _ = request.dataTaskNetwork(urlString: "https://postman-echo.com/cookies/set?name=value") // set a random cookie

        let requestMatch = SBTRequestMatch(url: "postman-echo.com")
        let requestId = app.blockCookiesInRequests(matching: requestMatch) ?? ""
        XCTAssertEqual(countCookies(), 0)
        XCTAssert(app.blockCookiesRequestsRemove(withId: requestId))
        XCTAssertEqual(countCookies(), 1)
    }

    func testMultipleBlockCookiesForSameRequestMatch() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        _ = request.dataTaskNetwork(urlString: "https://postman-echo.com/cookies/set?name=value") // set a random cookie

        XCTContext.runActivity(named: "When adding multiple block cookies for the same requests match") { _ in
            let requestMatch = SBTRequestMatch(url: "postman-echo.com")
            app.blockCookiesInRequests(matching: requestMatch, activeIterations: 1)
            app.blockCookiesInRequests(matching: requestMatch, activeIterations: 1)
        }

        XCTContext.runActivity(named: "They are removed when finishing active iterations") { _ in
            XCTAssertEqual(countCookies(), 0)
            XCTAssertEqual(countCookies(), 0)
            XCTAssertEqual(countCookies(), 1)
        }
    }
}

extension CookiesTest {
    override func setUp() {
        super.setUp()

        SBTUITestTunnelServer.perform(NSSelectorFromString("_connectionlessReset"))
        app.launchConnectionless { path, params -> String in
            SBTUITestTunnelServer.performCommand(path, params: params)
        }
    }
}
