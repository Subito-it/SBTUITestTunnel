// CookiesTest.swift
//
// Copyright (C) 2018 Subito.it S.r.l (www.subito.it)
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
    private var server: LocalHTTPServer!

    private func load(_ path: String) async throws {
        let url = try XCTUnwrap(URL(string: server.url(path)))
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 5)
        let (_, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(httpResponse.statusCode, 200)
    }

    private func assertCookieHeader(_ expected: String, file: StaticString = #filePath, line: UInt = #line) async throws {
        try await load("/cookies")
        let headers = try XCTUnwrap(server.requestHeaders("/cookies").last, file: file, line: line)
        XCTAssertEqual(headers["cookie"] ?? "", expected, file: file, line: line)
    }

    private func seedCookie() async throws {
        try await load("/cookies/set")
        // Verify the cookie reaches the server before installing a blocking rule.
        try await assertCookieHeader("name=value")
    }

    func testCookiesGetBlocked() async throws {
        try await seedCookie()

        let requestMatch = SBTRequestMatch(url: "127.0.0.1")
        app.blockCookiesInRequests(matching: requestMatch)

        try await assertCookieHeader("")
    }

    func testBlockCookiesAndRemove() async throws {
        try await seedCookie()

        let requestMatch = SBTRequestMatch(url: "127.0.0.1")
        app.blockCookiesInRequests(matching: requestMatch, activeIterations: 1)
        try await assertCookieHeader("")
        try await assertCookieHeader("name=value")
    }

    func testBlockCookiesAndRemoveAll() async throws {
        try await seedCookie()

        let requestMatch = SBTRequestMatch(url: "127.0.0.1")
        app.blockCookiesInRequests(matching: requestMatch)
        try await assertCookieHeader("")
        XCTAssert(app.blockCookiesRequestsRemoveAll())
        try await assertCookieHeader("name=value")
    }

    func testBlockCookiesAndRemoveSpecific() async throws {
        try await seedCookie()

        let requestMatch = SBTRequestMatch(url: "127.0.0.1")
        let requestId = try XCTUnwrap(app.blockCookiesInRequests(matching: requestMatch))
        try await assertCookieHeader("")
        XCTAssert(app.blockCookiesRequestsRemove(withId: requestId))
        try await assertCookieHeader("name=value")
    }

    func testMultipleBlockCookiesForSameRequestMatch() async throws {
        try await seedCookie()

        XCTContext.runActivity(named: "When adding multiple block cookies for the same requests match") { _ in
            let requestMatch = SBTRequestMatch(url: "127.0.0.1")
            app.blockCookiesInRequests(matching: requestMatch, activeIterations: 1)
            app.blockCookiesInRequests(matching: requestMatch, activeIterations: 1)
        }

        // Each matching rule blocks one request before it is removed.
        try await assertCookieHeader("")
        try await assertCookieHeader("")
        try await assertCookieHeader("name=value")
    }
}

extension CookiesTest {
    override func setUpWithError() throws {
        try super.setUpWithError()
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        server = try LocalHTTPServer(routes: [
            "/cookies/set": .init(statusCode: 200, headers: ["Set-Cookie": "name=value; Path=/"]),
            "/cookies": .init(statusCode: 200)
        ])

        SBTUITestTunnelServer.perform(NSSelectorFromString("_connectionlessReset"))
        app.launchConnectionless { path, params -> String in
            SBTUITestTunnelServer.performCommand(path, params: params)
        }
    }

    override func tearDown() {
        server = nil
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        super.tearDown()
    }
}
