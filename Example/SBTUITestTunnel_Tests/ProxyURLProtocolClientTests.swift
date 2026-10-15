// ProxyURLProtocolClientTests.swift
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

/// Drives SBTProxyURLProtocol directly to check the exact sequence of callbacks its client gets
class ProxyURLProtocolClientTests: XCTestCase {
    private var server: LocalHTTPServer!

    func testStubDeliveryStopsWhenTheClientStopsTheLoad() throws {
        app.stubRequests(matching: SBTRequestMatch(url: "127.0.0.1"), response: SBTStubResponse(response: "stub", returnCode: 200, responseTime: 0.0))
        let client = RecordingClient(stopsLoadingOnResponse: true)

        try startLoading(server.url("/destination"), client: client)

        assertEvents(of: client, settleTo: [.response(200)])
    }

    func testRewrittenDeliveryStopsWhenTheClientStopsTheLoad() throws {
        app.rewriteRequests(matching: SBTRequestMatch(url: "127.0.0.1"), rewrite: SBTRewrite(responseReplacement: [SBTRewriteReplacement(find: "destination", replace: "rewritten")]))
        let client = RecordingClient(stopsLoadingOnResponse: true)

        try startLoading(server.url("/destination"), client: client)

        assertEvents(of: client, settleTo: [.response(200)])
    }

    func testHeaderStubDeliveryStopsWhenTheClientStopsTheLoad() throws {
        app.stubRequests(matching: SBTRequestMatch(url: "127.0.0.1", requestHeaders: ["X-Stub": "yes"]), response: SBTStubResponse(response: "stub", returnCode: 200, responseTime: 0.0))
        let client = RecordingClient(stopsLoadingOnResponse: true)

        try startLoading(server.url("/destination"), headers: ["X-Stub": "yes"], client: client)

        assertEvents(of: client, settleTo: [.response(200)])
    }

    func testHeaderStubReplacesTheBodyAndFinishesOnce() throws {
        app.stubRequests(matching: SBTRequestMatch(url: "127.0.0.1", requestHeaders: ["X-Stub": "yes"]), response: SBTStubResponse(response: "stub", returnCode: 200, responseTime: 0.0))
        let client = RecordingClient()

        try startLoading(server.url("/destination"), headers: ["X-Stub": "yes"], client: client)

        assertEvents(of: client, settleTo: [.response(200), .data("stub"), .finish])
    }

    func testFailingStubSendsOnlyTheFailure() throws {
        app.stubRequests(matching: SBTRequestMatch(url: "127.0.0.1"), response: SBTStubFailureResponse(errorCode: URLError.notConnectedToInternet.rawValue, responseTime: 0.0))
        let client = RecordingClient()

        try startLoading(server.url("/destination"), client: client)

        assertEvents(of: client, settleTo: [.failure(URLError.notConnectedToInternet.rawValue)])
    }

    func testRewrittenRequestFailingWithoutResponseSendsOnlyTheFailure() throws {
        // Nothing listens on port 1 of the loopback interface, so the connection fails before any response
        app.rewriteRequests(matching: SBTRequestMatch(url: "127.0.0.1"), rewrite: SBTRewrite(urlReplacement: [SBTRewriteReplacement(find: "127\\.0\\.0\\.1:[0-9]+", replace: "127.0.0.1:1")]))
        let client = RecordingClient()

        try startLoading(server.url("/destination"), client: client)

        assertEvents(of: client, settleTo: [.failure(URLError.cannotConnectToHost.rawValue)])
    }

    func testProxiedLoadIsReleasedWhenStoppedBeforeTheThrottledTaskResumes() throws {
        app.throttleRequests(matching: SBTRequestMatch(url: "127.0.0.1"), responseTime: 2.0)
        let client = RecordingClient()

        weak var weakURLProtocol: URLProtocol?
        try autoreleasepool {
            let urlProtocol = try startLoading(server.url("/destination"), client: client)
            urlProtocol.stopLoading()
            weakURLProtocol = urlProtocol
        }

        wait(withTimeout: 5.0) { weakURLProtocol == nil }
        XCTAssertEqual(client.events, [])
        XCTAssertEqual(server.hits("/destination"), 0)
    }

    @discardableResult
    private func startLoading(_ urlString: String, headers: [String: String] = [:], client: RecordingClient) throws -> URLProtocol {
        var request = URLRequest(url: URL(string: urlString)!)
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        let protocolClass = try XCTUnwrap(NSClassFromString("SBTProxyURLProtocol") as? URLProtocol.Type)
        let urlProtocol = protocolClass.init(request: request, cachedResponse: nil, client: client)
        // The test thread becomes the client thread, so the client gets its callbacks while the test spins the main run loop
        client.willStartLoading()
        urlProtocol.startLoading()

        return urlProtocol
    }

    /// Waits for the load to settle, then checks that the client got exactly these callbacks
    private func assertEvents(of client: RecordingClient, settleTo expectedEvents: [RecordingClient.Event], file: StaticString = #filePath, line: UInt = #line) {
        wait(withTimeout: 10.0) { client.events.count >= expectedEvents.count }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        XCTAssertEqual(client.events, expectedEvents, file: file, line: line)
        XCTAssertEqual(client.offThreadEvents, [], "Callbacks must arrive on the thread that started the load", file: file, line: line)
    }
}

private final class RecordingClient: NSObject, URLProtocolClient {
    enum Event: Equatable {
        case redirect
        case response(Int)
        case data(String)
        case finish
        case failure(Int)
    }

    private let stopsLoadingOnResponse: Bool
    private let lock = NSLock()
    private var recordedEvents = [Event]()
    private var recordedOffThreadEvents = [Event]()
    private var loadingThread: Thread?

    init(stopsLoadingOnResponse: Bool = false) {
        self.stopsLoadingOnResponse = stopsLoadingOnResponse
    }

    var events: [Event] {
        lock.withLock { recordedEvents }
    }

    /// Callbacks that didn't arrive on the thread that started the load
    var offThreadEvents: [Event] {
        lock.withLock { recordedOffThreadEvents }
    }

    func willStartLoading() {
        lock.withLock { loadingThread = .current }
    }

    private func record(_ event: Event) {
        let thread = Thread.current
        lock.withLock {
            recordedEvents.append(event)
            if thread != loadingThread {
                recordedOffThreadEvents.append(event)
            }
        }
    }

    func urlProtocol(_: URLProtocol, wasRedirectedTo _: URLRequest, redirectResponse _: URLResponse) {
        record(.redirect)
    }

    func urlProtocol(_: URLProtocol, cachedResponseIsValid _: CachedURLResponse) {}

    func urlProtocol(_ urlProtocol: URLProtocol, didReceive response: URLResponse, cacheStoragePolicy _: URLCache.StoragePolicy) {
        record(.response((response as? HTTPURLResponse)?.statusCode ?? 0))
        if stopsLoadingOnResponse {
            urlProtocol.stopLoading()
        }
    }

    func urlProtocol(_: URLProtocol, didLoad data: Data) {
        record(.data(String(decoding: data, as: UTF8.self)))
    }

    func urlProtocolDidFinishLoading(_: URLProtocol) {
        record(.finish)
    }

    func urlProtocol(_: URLProtocol, didFailWithError error: Error) {
        record(.failure((error as NSError).code))
    }

    func urlProtocol(_: URLProtocol, didReceive _: URLAuthenticationChallenge) {}

    func urlProtocol(_: URLProtocol, didCancel _: URLAuthenticationChallenge) {}
}

extension ProxyURLProtocolClientTests {
    override func setUpWithError() throws {
        try super.setUpWithError()

        server = try LocalHTTPServer(routes: ["/destination": .init(statusCode: 200, body: "destination body")])

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
