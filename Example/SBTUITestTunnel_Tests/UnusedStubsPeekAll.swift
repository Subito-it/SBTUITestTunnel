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
        let removeAfterIterations: UInt = 2
        app.stubRequests(matching: match,
                         response: SBTStubResponse(response: ["stubbed": 1]),
                         removeAfterIterations: removeAfterIterations)
        
        let given = app.unusedStubsPeekAll()
        let expected: [SBTRequestMatch: UInt] = [match: removeAfterIterations]
        assertUnusedStubs(given, expected: expected)
    }
    
    func testForOneMatchAndRemoveAfterTwoIterationsUsedOnce() {
        let match = SBTRequestMatch(url: "httpbin.org")
        let removeAfterIterations: UInt = 2
        app.stubRequests(matching: match,
                         response: SBTStubResponse(response: ["stubbed": 1]),
                         removeAfterIterations: removeAfterIterations)
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get")
        XCTAssert(request.isStubbed(result))
        
        let given = app.unusedStubsPeekAll()
        let expected: [SBTRequestMatch: UInt] = [match: 1]
        assertUnusedStubs(given, expected: expected)
    }
    
    func testForOneMatchAndRemoveAfterTwoIterationsUsedTwice() {
        let match = SBTRequestMatch(url: "httpbin.org")
        let removeAfterIterations: UInt = 2
        app.stubRequests(matching: match,
                         response: SBTStubResponse(response: ["stubbed": 1]),
                         removeAfterIterations: removeAfterIterations)
        
        for _ in 0...1 {
            let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get")
            XCTAssert(request.isStubbed(result))
        }
        
        let given = app.unusedStubsPeekAll()
        let expected = [SBTRequestMatch: UInt]()
        assertUnusedStubs(given, expected: expected)
    }
    
    func testForOneMatchAndWithoutDefiningRemoveAfterTwoIterationsNotUsed() {
        let match = SBTRequestMatch(url: "httpbin.org")
        app.stubRequests(matching: match,
                         response: SBTStubResponse(response: ["stubbed": 1]))
        
        let given = app.unusedStubsPeekAll()
        let expected = [SBTRequestMatch: UInt]()
        assertUnusedStubs(given, expected: expected)
    }
    
    func testForOneMatchAndWithoutDefiningRemoveAfterTwoIterationsUsedOnce() {
        let match = SBTRequestMatch(url: "httpbin.org")
        app.stubRequests(matching: match,
                         response: SBTStubResponse(response: ["stubbed": 1]))
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get")
        XCTAssert(request.isStubbed(result))
        
        let given = app.unusedStubsPeekAll()
        let expected = [SBTRequestMatch: UInt]()
        assertUnusedStubs(given, expected: expected)
    }
    
    func testForOneMatchAndWithoutDefiningZeroRemoveAfterTwoIterationsNotUsed() {
        let match = SBTRequestMatch(url: "httpbin.org")
        let removeAfterIterations: UInt = 0
        app.stubRequests(matching: match,
                         response: SBTStubResponse(response: ["stubbed": 1]),
                         removeAfterIterations: removeAfterIterations)
        
        let given = app.unusedStubsPeekAll()
        let expected = [SBTRequestMatch: UInt]()
        assertUnusedStubs(given, expected: expected)
    }
    
    func testForOneMatchAndWithoutDefiningZeroRemoveAfterTwoIterationsUsedOnce() {
        let match = SBTRequestMatch(url: "httpbin.org")
        let removeAfterIterations: UInt = 0
        app.stubRequests(matching: match,
                         response: SBTStubResponse(response: ["stubbed": 1]),
                         removeAfterIterations: removeAfterIterations)
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get")
        XCTAssert(request.isStubbed(result))
        
        let given = app.unusedStubsPeekAll()
        let expected = [SBTRequestMatch: UInt]()
        assertUnusedStubs(given, expected: expected)
    }
    
    func testForTwoMatchesAndRemoveAfterTwoIterationsForOneNotUsed() {
        let firstMatch = SBTRequestMatch(url: "httpbin.org")
        let secondMatch = SBTRequestMatch(url: "go.gl")
        let removeAfterIterations: UInt = 2
        app.stubRequests(matching: firstMatch,
                         response: SBTStubResponse(response: ["stubbed": 1]),
                         removeAfterIterations: removeAfterIterations)
        app.stubRequests(matching: secondMatch,
                         response: SBTStubResponse(response: ["stubbed": 1]),
                         removeAfterIterations: removeAfterIterations)
        
        let given = app.unusedStubsPeekAll()
        let expected: [SBTRequestMatch: UInt] = [firstMatch: removeAfterIterations,
                                                 secondMatch: removeAfterIterations]
        assertUnusedStubs(given, expected: expected)
    }
    
    func testForTwoMatchesAndRemoveAfterTwoIterationsForOneUsedOnce() {
        let firstMatch = SBTRequestMatch(url: "httpbin.org")
        let secondMatch = SBTRequestMatch(url: "go.gl")
        let removeAfterIterations: UInt = 2
        app.stubRequests(matching: firstMatch,
                         response: SBTStubResponse(response: ["stubbed": 1]),
                         removeAfterIterations: removeAfterIterations)
        app.stubRequests(matching: secondMatch,
                         response: SBTStubResponse(response: ["stubbed": 1]),
                         removeAfterIterations: removeAfterIterations)
        
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/get")
        XCTAssert(request.isStubbed(result))
        
        let given = app.unusedStubsPeekAll()
        let expected: [SBTRequestMatch: UInt] = [firstMatch: 1, secondMatch: 2]
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
    func assertUnusedStubs(_ given: [SBTRequestMatch: NSNumber],
                           expected: [SBTRequestMatch: UInt],
                           file: StaticString = #file,
                           line: UInt = #line) {
        let cleanGiven = given.mapValues({ $0.uintValue })
        
        XCTAssertEqual(cleanGiven, expected, file: file, line: line)
    }
}
