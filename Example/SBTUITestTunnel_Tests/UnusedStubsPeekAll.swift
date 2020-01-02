//
//  UnusedStubsPeekAll.swift
//  SBTUITestTunnel_Tests
//
//  Created by DMITRY KULAKOV on 20.11.2019.
//  Copyright © 2019 Tomas Camin. All rights reserved.
//

import SBTUITestTunnelClient
import SBTUITestTunnelServer
import Foundation
import XCTest

class UnusedStubsPeekAllTests: XCTestCase {

    private let request = NetworkRequests()
    
    func testForOneMatchAndRemoveAfterTwoIterationsNotUsed() {
        let match = SBTRequestMatch(url: "httpbin.org")
        let removeAfterIterations = 2
        let response = SBTStubResponse(response: ["stubbed": 1], activeIterations: removeAfterIterations)
        
        app.stubRequests(matching: match, response: response)
        
        let given = unusedStubsPeekAll()
        let expected: [SBTRequestMatch: Int] = [match: removeAfterIterations]
        assertUnusedStubs(given, expected: expected)
    }
    
    func testForOneMatchAndRemoveAfterTwoIterationsUsedOnce() {
        let match = SBTRequestMatch(url: "httpbin.org")
        let removeAfterIterations = 2
        let response = SBTStubResponse(response: ["stubbed": 1], activeIterations: removeAfterIterations)
        
        app.stubRequests(matching: match, response: response)

        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get")
        XCTAssert(request.isStubbed(result))

        let given = unusedStubsPeekAll()
        let expected: [SBTRequestMatch: Int] = [match: 1]
        assertUnusedStubs(given, expected: expected)
    }

    func testForOneMatchAndRemoveAfterTwoIterationsUsedTwice() {
        let match = SBTRequestMatch(url: "httpbin.org")
        let removeAfterIterations = 2
        let response = SBTStubResponse(response: ["stubbed": 1], activeIterations: removeAfterIterations)
        
        app.stubRequests(matching: match, response: response)

        for _ in 0...1 {
            let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get")
            XCTAssert(request.isStubbed(result))
        }

        let given = unusedStubsPeekAll()
        let expected = [SBTRequestMatch: Int]()
        assertUnusedStubs(given, expected: expected)
    }

    func testForOneMatchAndWithoutDefiningRemoveAfterTwoIterationsNotUsed() {
        let match = SBTRequestMatch(url: "httpbin.org")
        let response = SBTStubResponse(response: ["stubbed": 1])
        
        app.stubRequests(matching: match, response: response)

        let given = unusedStubsPeekAll()
        let expected = [SBTRequestMatch: Int]()
        assertUnusedStubs(given, expected: expected)
    }

    func testForOneMatchAndWithoutDefiningRemoveAfterTwoIterationsUsedOnce() {
        let match = SBTRequestMatch(url: "httpbin.org")
        let response = SBTStubResponse(response: ["stubbed": 1])
        
        app.stubRequests(matching: match, response: response)

        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get")
        XCTAssert(request.isStubbed(result))

        let given = unusedStubsPeekAll()
        let expected = [SBTRequestMatch: Int]()
        assertUnusedStubs(given, expected: expected)
    }

    func testForOneMatchAndWithoutDefiningZeroRemoveAfterTwoIterationsNotUsed() {
        let match = SBTRequestMatch(url: "httpbin.org")
        let removeAfterIterations = 0
        let response = SBTStubResponse(response: ["stubbed": 1], activeIterations: removeAfterIterations)
        
        app.stubRequests(matching: match, response: response)

        let given = unusedStubsPeekAll()
        let expected = [SBTRequestMatch: Int]()
        assertUnusedStubs(given, expected: expected)
    }

    func testForOneMatchAndWithoutDefiningZeroRemoveAfterTwoIterationsUsedOnce() {
        let match = SBTRequestMatch(url: "httpbin.org")
        let removeAfterIterations = 0
        let response = SBTStubResponse(response: ["stubbed": 1], activeIterations: removeAfterIterations)
        
        app.stubRequests(matching: match, response: response)

        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get")
        XCTAssert(request.isStubbed(result))

        let given = unusedStubsPeekAll()
        let expected = [SBTRequestMatch: Int]()
        assertUnusedStubs(given, expected: expected)
    }

    func testForTwoMatchesAndRemoveAfterTwoIterationsForOneNotUsed() {
        let firstMatch = SBTRequestMatch(url: "httpbin.org")
        let secondMatch = SBTRequestMatch(url: "go.gl")
        let removeAfterIterations = 2
        let response = SBTStubResponse(response: ["stubbed": 1], activeIterations: removeAfterIterations)
        
        app.stubRequests(matching: firstMatch, response: response)
        app.stubRequests(matching: secondMatch, response: response)

        let given = unusedStubsPeekAll()
        let expected: [SBTRequestMatch: Int] = [firstMatch: removeAfterIterations,
                                                secondMatch: removeAfterIterations]
        assertUnusedStubs(given, expected: expected)
    }

    func testForTwoMatchesAndRemoveAfterTwoIterationsForOneUsedOnce() {
        let firstMatch = SBTRequestMatch(url: "httpbin.org")
        let secondMatch = SBTRequestMatch(url: "go.gl")
        let removeAfterIterations = 2
        let response = SBTStubResponse(response: ["stubbed": 1], activeIterations: removeAfterIterations)
        
        app.stubRequests(matching: firstMatch, response: response)
        app.stubRequests(matching: secondMatch, response: response)

        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get")
        XCTAssert(request.isStubbed(result))

        let given = unusedStubsPeekAll()
        let expected: [SBTRequestMatch: Int] = [firstMatch: 1, secondMatch: 2]
        assertUnusedStubs(given, expected: expected)
    }
}

extension UnusedStubsPeekAllTests {
    override func setUp() {
        app.launchConnectionless { (path, params) -> String in
            return SBTUITestTunnelServer.performCommand(path, params: params)
        }
    }
}

extension UnusedStubsPeekAllTests {
    func unusedStubsPeekAll() -> [SBTRequestMatch : SBTStubResponse] {
        return app.stubRequestsAll().filter { $0.value.activeIterations > 0 }
    }
    
    func assertUnusedStubs(_ given: [SBTRequestMatch: SBTStubResponse],
                           expected: [SBTRequestMatch: Int],
                           file: StaticString = #file,
                           line: UInt = #line) {
        let cleanGiven = given.mapValues { $0.activeIterations }
        
        XCTAssertEqual(cleanGiven, expected, file: file, line: line)
    }
}
