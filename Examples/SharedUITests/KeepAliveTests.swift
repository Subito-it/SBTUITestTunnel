// KeepAliveTests.swift
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

class KeepAliveTests: XCTestCase {
    private let request = NetworkRequests()
    private let testServer = TestHTTPServer()
    private var serverURL: String = ""
    
    override func setUp() {
        super.setUp()
        
        let port = testServer.start(enableKeepAlive: true, keepAliveTimeout: 5)
        XCTAssertNotEqual(port, 0, "Server failed to start with a valid port")
        serverURL = "http://localhost:\(port)"
    }
    
    override func tearDown() {
        testServer.stop()
        super.tearDown()
    }
    
    func testKeepAliveHeadersInResponse() {
        let result = request.dataTaskNetworkWithResponse(urlString: "\(serverURL)/test")
        
        XCTAssertEqual(result.headers["Connection"]?.lowercased(), "keep-alive", "Connection header should be set to keep-alive")
        
        XCTAssertNotNil(result.headers["Keep-Alive"], "Keep-Alive header should be present")
        XCTAssertTrue(result.headers["Keep-Alive"]?.contains("timeout=") ?? false, "Keep-Alive header should contain timeout")
    }
    
    func testMultipleRequestsReuseConnection() {
        _ = request.dataTaskNetwork(urlString: "\(serverURL)/test1")
        let firstRequestInfo = testServer.nextRequestInfo()
        
        _ = request.dataTaskNetwork(urlString: "\(serverURL)/test2")
        let secondRequestInfo = testServer.nextRequestInfo()
        
        _ = request.dataTaskNetwork(urlString: "\(serverURL)/test3")
        let thirdRequestInfo = testServer.nextRequestInfo()
        
        XCTAssertEqual(firstRequestInfo.connectionId, secondRequestInfo.connectionId, "First and second requests should use the same connection")
        XCTAssertEqual(secondRequestInfo.connectionId, thirdRequestInfo.connectionId, "Second and third requests should use the same connection")
        
        XCTAssertEqual(firstRequestInfo.requestCount, 1, "First request should have request count 1")
        XCTAssertEqual(secondRequestInfo.requestCount, 2, "Second request should have request count 2")
        XCTAssertEqual(thirdRequestInfo.requestCount, 3, "Third request should have request count 3")
    }
    
    func testConnectionCloseAfterTimeout() {
        _ = request.dataTaskNetwork(urlString: "\(serverURL)/test1")
        let firstRequestInfo = testServer.nextRequestInfo()
        
        Thread.sleep(forTimeInterval: 7.0)
        
        _ = request.dataTaskNetwork(urlString: "\(serverURL)/test2")
        let secondRequestInfo = testServer.nextRequestInfo()
        
        XCTAssertNotEqual(firstRequestInfo.connectionId, secondRequestInfo.connectionId, "After timeout, a new connection should be used")
        XCTAssertEqual(secondRequestInfo.requestCount, 1, "New connection should have request count 1")
    }
    
    func testDisablingKeepAlive() {
        testServer.stop()
        let port = testServer.start(enableKeepAlive: false)
        XCTAssertNotEqual(port, 0, "Server failed to start with a valid port")
        serverURL = "http://localhost:\(port)"
        
        _ = request.dataTaskNetwork(urlString: "\(serverURL)/test1")
        let firstRequestInfo = testServer.nextRequestInfo()
        
        _ = request.dataTaskNetwork(urlString: "\(serverURL)/test2")
        let secondRequestInfo = testServer.nextRequestInfo()
        
        // Connection IDs should be different because keep-alive is disabled
        XCTAssertNotEqual(firstRequestInfo.connectionId, secondRequestInfo.connectionId, "With keep-alive disabled, connections should not be reused")
        XCTAssertEqual(firstRequestInfo.requestCount, 1, "First request should have request count 1")
        XCTAssertEqual(secondRequestInfo.requestCount, 1, "Second request should have request count 1")
    }
}

class TestHTTPServer {
    private var server: SBTWebServer?
    private var requestInfoQueue = DispatchQueue(label: "com.example.requestinfo")
    private var nextRequestInfos: [(connectionId: Int, requestCount: Int)] = []
    private var connectionCounter = 0
    private var lastRemoteAddressMap: [String: Int] = [:]
    private var connectionRequestCountMap: [Int: Int] = [:]
    
    func start(enableKeepAlive: Bool = true, keepAliveTimeout: UInt = 15) -> UInt {
        let server = SBTWebServer()
        defer { self.server = server }
        
        server.addDefaultHandler(forMethod: "GET", request: SBTWebServerRequest.self, processBlock: { [weak self] request in
            guard let self else {
                return SBTWebServerDataResponse(text: "Server error")
            }
            
            let remoteAddressKey = request.remoteAddressString
            
            // Track connections by remote address and port
            var connectionId = 0
            var requestCount = 1
            
            requestInfoQueue.sync {
                // If we have seen this remote address before and keep-alive is enabled,
                // it might be the same connection
                if enableKeepAlive, let existingConnectionId = self.lastRemoteAddressMap[remoteAddressKey] {
                    connectionId = existingConnectionId
                    requestCount = (self.connectionRequestCountMap[connectionId] ?? 0) + 1
                    self.connectionRequestCountMap[connectionId] = requestCount
                } else {
                    // New connection
                    self.connectionCounter += 1
                    connectionId = self.connectionCounter
                    requestCount = 1
                    self.lastRemoteAddressMap[remoteAddressKey] = connectionId
                    self.connectionRequestCountMap[connectionId] = requestCount
                }
                
                self.nextRequestInfos.append((connectionId: connectionId, requestCount: requestCount))
            }
            
            // Create a response with some test data
            let response = SBTWebServerDataResponse(text: "Test response")
            return response
        })
        
        // Configure server with keep-alive options
        let options: [String: Any] = [
            SBTWebServerOption_Port: UInt(0), // Let the OS pick a random port
            SBTWebServerOption_BindToLocalhost: true,
            SBTWebServerOption_EnableKeepAlive: enableKeepAlive,
            SBTWebServerOption_KeepAliveTimeout: keepAliveTimeout,
            SBTWebServerOption_AutomaticallySuspendInBackground: false
        ]
        
        do {
            try server.start(options: options)
            return server.port
        } catch {
            print("Failed to start server: \(error)")
        }

        return 0
    }
    
    func stop() {
        server?.stop()
        server = nil
    }
    
    func nextRequestInfo() -> (connectionId: Int, requestCount: Int) {
        var result: (connectionId: Int, requestCount: Int) = (0, 0)
        var isFulfilled = false
        
        // Wait for the next request info to be available
        let expectation = XCTestExpectation(description: "Get next request info")
        
        DispatchQueue.global().async {
            while !isFulfilled {
                self.requestInfoQueue.sync {
                    if !self.nextRequestInfos.isEmpty {
                        result = self.nextRequestInfos.removeFirst()
                        isFulfilled = true
                        expectation.fulfill()
                    }
                }
                if isFulfilled {
                    break
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
        
        _ = XCTWaiter().wait(for: [expectation], timeout: 10.0)
        return result
    }
}
