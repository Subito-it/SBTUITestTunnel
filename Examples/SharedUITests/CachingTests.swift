// CachingTests.swift
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

/// Requests passed through the proxy are cached and revalidated as they would be without it
class CachingTests: XCTestCase {
    private typealias Load = (URLRequest) async throws -> (Data, URLResponse)

    private var server: LocalHTTPServer!

    func testSharedSessionCachesPassedThroughResponses() async throws {
        try await assertCachesPassedThroughResponses(load: URLSession.shared.data(for:))
    }

    func testDefaultConfigurationSessionCachesPassedThroughResponses() async throws {
        let session = URLSession(configuration: .default)
        defer { session.invalidateAndCancel() }

        try await assertCachesPassedThroughResponses(load: session.data(for:))
    }

    func testEphemeralConfigurationSessionCachesPassedThroughResponses() async throws {
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }

        try await assertCachesPassedThroughResponses(load: session.data(for:))
    }

    func testSessionWithItsOwnCacheCachesPassedThroughResponses() async throws {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 1_024 * 1_024, diskCapacity: 0)
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        try await assertCachesPassedThroughResponses(load: session.data(for:))
    }

    func testDelegateSessionCachesPassedThroughResponses() async throws {
        let delegate = DataTaskDelegate()
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }

        try await assertCachesPassedThroughResponses { request in
            try await delegate.load(request, in: session)
        }
    }

    func testRequestsIgnoringTheLocalCacheAreNotRevalidated() async throws {
        app.monitorRequests(matching: SBTRequestMatch(url: "127.0.0.1"))

        for _ in 0 ..< 2 {
            let body = try await load("/revalidated", cachePolicy: .reloadIgnoringLocalCacheData, using: URLSession.shared.data(for:))
            XCTAssertEqual(body, "revalidated body")
        }

        XCTAssertEqual(server.requestHeaders("/revalidated").map { $0["if-none-match"] }, [nil, nil])
    }

    func testStubbedResponsesAreNotCached() async throws {
        app.monitorRequests(matching: SBTRequestMatch(url: "127.0.0.1"))
        app.stubRequests(matching: SBTRequestMatch(url: "fresh"), response: SBTStubResponse(response: "stubbed body", headers: freshHeaders, contentType: "text/plain", returnCode: 200, responseTime: 0.0, activeIterations: 1))

        let stubbedBody = try await load("/fresh", using: URLSession.shared.data(for:))
        let firstBody = try await load("/fresh", using: URLSession.shared.data(for:))
        let secondBody = try await load("/fresh", using: URLSession.shared.data(for:))

        XCTContext.runActivity(named: "The stubbed body is not served once the stub is gone") { _ in
            XCTAssertEqual(stubbedBody, "stubbed body")
            XCTAssertEqual(firstBody, "fresh body")
        }

        XCTContext.runActivity(named: "The response that reached the server gets cached") { _ in
            XCTAssertEqual(secondBody, "fresh body")
            XCTAssertEqual(server.hits("/fresh"), 1)
        }
    }

    private func assertCachesPassedThroughResponses(load: Load, file: StaticString = #filePath, line: UInt = #line) async throws {
        app.monitorRequests(matching: SBTRequestMatch(url: "127.0.0.1"))

        var bodies = [String]()
        for path in ["/revalidated", "/revalidated", "/fresh", "/fresh"] {
            try await bodies.append(self.load(path, using: load))
        }

        XCTContext.runActivity(named: "The caller always gets the full response") { _ in
            XCTAssertEqual(bodies, ["revalidated body", "revalidated body", "fresh body", "fresh body"], file: file, line: line)
        }

        XCTContext.runActivity(named: "A stale response is revalidated with its ETag") { _ in
            XCTAssertEqual(server.requestHeaders("/revalidated").map { $0["if-none-match"] }, [nil, revalidatedETag], file: file, line: line)
        }

        XCTContext.runActivity(named: "A fresh response is served from the cache") { _ in
            XCTAssertEqual(server.hits("/fresh"), 1, file: file, line: line)
        }

        XCTContext.runActivity(named: "Every load is monitored") { _ in
            XCTAssertEqual(app.monitoredRequestsFlushAll().count, 4, file: file, line: line)
        }
    }

    private func load(_ path: String, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, using load: Load) async throws -> String {
        let url = try XCTUnwrap(URL(string: server.url(path)))
        let (data, response) = try await load(URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: 5.0))
        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(httpResponse.statusCode, 200)

        return String(decoding: data, as: UTF8.self)
    }

    private let revalidatedETag = "\"revalidated\""
    private let freshHeaders = ["Cache-Control": "max-age=600", "ETag": "\"fresh\""]
}

private final class DataTaskDelegate: NSObject, URLSessionDataDelegate {
    private let lock = NSLock()
    private var data = Data()
    private var continuation: CheckedContinuation<(Data, URLResponse), Error>?

    func load(_ request: URLRequest, in session: URLSession) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            lock.withLock {
                data = Data()
                self.continuation = continuation
            }
            session.dataTask(with: request).resume()
        }
    }

    func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
        lock.withLock { self.data.append(data) }
    }

    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let (data, continuation) = lock.withLock { (self.data, self.continuation) }
        if let error {
            continuation?.resume(throwing: error)
        } else if let response = task.response {
            continuation?.resume(returning: (data, response))
        } else {
            continuation?.resume(throwing: URLError(.badServerResponse))
        }
    }
}

extension CachingTests {
    override func setUpWithError() throws {
        try super.setUpWithError()

        URLCache.shared.removeAllCachedResponses()
        server = try LocalHTTPServer(routes: [
            "/revalidated": .init(statusCode: 200, headers: ["Cache-Control": "no-cache", "ETag": revalidatedETag], body: "revalidated body"),
            "/fresh": .init(statusCode: 200, headers: freshHeaders, body: "fresh body")
        ])

        SBTUITestTunnelServer.perform(NSSelectorFromString("_connectionlessReset"))
        app.launchConnectionless { path, params -> String in
            SBTUITestTunnelServer.performCommand(path, params: params)
        }
    }

    override func tearDown() {
        server = nil
        URLCache.shared.removeAllCachedResponses()
        super.tearDown()
    }
}
