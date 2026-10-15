// RedirectTests.swift
//
// Copyright (C) 2026 Subito.it S.r.l (www.subito.it)
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

class RedirectTests: XCTestCase {
    private let request = NetworkRequests()
    private var server: LocalHTTPServer!

    func testMonitoredRedirectChainLoadsEachURLOnce() {
        app.monitorRequests(matching: SBTRequestMatch(url: "127.0.0.1"))

        let result = request.dataTaskNetworkWithResponse(urlString: server.url("/redirect"))

        XCTContext.runActivity(named: "The caller gets the final response") { _ in
            XCTAssertEqual(result.response.statusCode, 200)
            XCTAssertEqual(String(decoding: result.data, as: UTF8.self), "destination body")
        }

        XCTContext.runActivity(named: "Each URL of the chain is requested once") { _ in
            XCTAssertEqual(server.hits("/redirect"), 1)
            XCTAssertEqual(server.hits("/hop"), 1)
            XCTAssertEqual(server.hits("/destination"), 1)
        }

        XCTContext.runActivity(named: "Each hop is monitored with its own response") { _ in
            XCTAssert(app.waitForMonitoredRequests(matching: SBTRequestMatch(url: "127.0.0.1"), timeout: 5.0, iterations: 3))
            let monitoredHops = app.monitoredRequestsFlushAll().map { "\($0.request?.url?.path ?? "") \($0.response?.statusCode ?? 0)" }
            XCTAssertEqual(Set(monitoredHops), ["/redirect 302", "/hop 302", "/destination 200"])
            XCTAssertEqual(monitoredHops.count, 3)
        }
    }

    func testMonitoredDeclinedRedirectCompletesWithTheRedirectResponse() {
        app.monitorRequests(matching: SBTRequestMatch(url: "127.0.0.1"))

        let result = loadDecliningRedirects(server.url("/redirect"))

        XCTAssertEqual(result.completions, 1)
        XCTAssertNil(result.error)
        XCTAssertEqual(result.response?.statusCode, 302)
        XCTAssertEqual(String(decoding: result.data, as: UTF8.self), "redirect body")
        XCTAssertEqual(server.hits("/redirect"), 1)
        XCTAssertEqual(server.hits("/hop"), 0)
    }

    func testMonitoredRedirectFollowedLateLoadsTheDestinationOnce() {
        app.monitorRequests(matching: SBTRequestMatch(url: "127.0.0.1"))

        let result = loadFollowingRedirectsLate(server.url("/redirect"))

        XCTAssertEqual(result.completions, 1)
        XCTAssertNil(result.error)
        XCTAssertEqual(result.response?.statusCode, 200)
        XCTAssertEqual(String(decoding: result.data, as: UTF8.self), "destination body")
        XCTAssertEqual(server.hits("/redirect"), 1)
        XCTAssertEqual(server.hits("/hop"), 1)
        XCTAssertEqual(server.hits("/destination"), 1)
    }

    func testStubbedRedirectFollowedLateLoadsTheDestination() {
        app.stubRequests(matching: SBTRequestMatch(url: "stubbed-redirect"), response: stubbedRedirect)

        let result = loadFollowingRedirectsLate(server.url("/stubbed-redirect"))

        XCTAssertEqual(result.completions, 1)
        XCTAssertNil(result.error)
        XCTAssertEqual(result.response?.statusCode, 200)
        XCTAssertEqual(String(decoding: result.data, as: UTF8.self), "destination body")
        XCTAssertEqual(server.hits("/destination"), 1)
    }

    func testStubbedRedirectLoadsTheDestination() {
        app.stubRequests(matching: SBTRequestMatch(url: "stubbed-redirect"), response: stubbedRedirect)

        let result = request.dataTaskNetworkWithResponse(urlString: server.url("/stubbed-redirect"))

        XCTAssertEqual(result.response.statusCode, 200)
        XCTAssertEqual(String(decoding: result.data, as: UTF8.self), "destination body")
        XCTAssertEqual(server.hits("/stubbed-redirect"), 0)
        XCTAssertEqual(server.hits("/destination"), 1)
    }

    func testStubbedDeclinedRedirectCompletesWithTheStubbedResponse() {
        app.stubRequests(matching: SBTRequestMatch(url: "stubbed-redirect"), response: stubbedRedirect)

        let result = loadDecliningRedirects(server.url("/stubbed-redirect"))

        XCTAssertEqual(result.completions, 1)
        XCTAssertNil(result.error)
        XCTAssertEqual(result.response?.statusCode, 302)
        XCTAssertEqual(String(decoding: result.data, as: UTF8.self), "stubbed redirect body")
        XCTAssertEqual(server.hits("/destination"), 0)
    }

    private var stubbedRedirect: SBTStubResponse {
        SBTStubResponse(response: "stubbed redirect body", headers: ["Location": server.url("/destination")], contentType: "text/plain", returnCode: 302, responseTime: 0.0)
    }

    private func loadDecliningRedirects(_ urlString: String) -> RedirectHandlingDelegate {
        load(urlString, delegate: RedirectHandlingDelegate(followsRedirects: false))
    }

    /// The decision arrives after the redirected load has delivered the redirect response and its body
    private func loadFollowingRedirectsLate(_ urlString: String) -> RedirectHandlingDelegate {
        load(urlString, delegate: RedirectHandlingDelegate(followsRedirects: true, decisionDelay: 0.5))
    }

    private func load(_ urlString: String, delegate: RedirectHandlingDelegate) -> RedirectHandlingDelegate {
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: .main)
        defer { session.invalidateAndCancel() }

        session.dataTask(with: URL(string: urlString)!).resume()
        wait(withTimeout: 10.0) { delegate.completions > 0 }

        return delegate
    }
}

private final class RedirectHandlingDelegate: NSObject, URLSessionDataDelegate {
    private let followsRedirects: Bool
    private let decisionDelay: TimeInterval
    private(set) var completions = 0
    private(set) var response: HTTPURLResponse?
    private(set) var data = Data()
    private(set) var error: Error?

    init(followsRedirects: Bool, decisionDelay: TimeInterval = 0.0) {
        self.followsRedirects = followsRedirects
        self.decisionDelay = decisionDelay
    }

    func urlSession(_: URLSession, task _: URLSessionTask, willPerformHTTPRedirection _: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        let followsRedirects = followsRedirects
        DispatchQueue.main.asyncAfter(deadline: .now() + decisionDelay) {
            completionHandler(followsRedirects ? request : nil)
        }
    }

    func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
        self.data.append(data)
    }

    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        completions += 1
        response = task.response as? HTTPURLResponse
        self.error = error
    }
}

extension RedirectTests {
    override func setUpWithError() throws {
        try super.setUpWithError()

        server = try LocalHTTPServer(routes: [
            "/redirect": .init(statusCode: 302, headers: ["Location": "/hop"], body: "redirect body"),
            "/hop": .init(statusCode: 302, headers: ["Location": "/destination"], body: "hop body"),
            "/destination": .init(statusCode: 200, body: "destination body")
        ])

        SBTUITestTunnelServer.perform(NSSelectorFromString("_connectionlessReset"))
        app.launchConnectionless { path, params -> String in
            SBTUITestTunnelServer.performCommand(path, params: params)
        }
    }

    override func tearDown() {
        server = nil
        super.tearDown()
    }
}
