//
//  CookiesTest.swift
//  SBTUITestTunnel_Tests
//
//  Created by Tomas Camin on 06/02/2018.
//  Copyright © 2018 Tomas Camin. All rights reserved.
//

import SBTUITestTunnel
import Foundation

class CookiesTest: XCTestCase {
    
    private let request = NetworkRequests()
    
    private func countCookies() -> Int {
        let result = request.dataTaskNetwork(urlString: "http://httpbin.org/cookies")
        let json = request.json(result)

        return (json["cookies"] as? [String : Any])?.keys.count ?? 0
    }
    
    func testCookiesGetBlocked() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/cookies/set?name=value") // set a random cookie

        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        app.blockCookiesInRequests(matching: requestMatch)
        
        XCTAssertEqual(countCookies(), 0)
    }
    
    func testBlockCookiesAndRemove() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/cookies/set?name=value") // set a random cookie
        
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        app.blockCookiesInRequests(matching: requestMatch, iterations: 1)
        XCTAssertEqual(countCookies(), 0)
        XCTAssertEqual(countCookies(), 1)
    }
    
    func testBlockCookiesAndRemoveAll() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/cookies/set?name=value") // set a random cookie
        
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        app.blockCookiesInRequests(matching: requestMatch)
        XCTAssertEqual(countCookies(), 0)
        XCTAssert(app.blockCookiesRequestsRemoveAll())
        XCTAssertEqual(countCookies(), 1)
    }
    
    func testBlockCookiesAndRemoveSpecific() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/cookies/set?name=value") // set a random cookie
        
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        let requestId = app.blockCookiesInRequests(matching: requestMatch) ?? ""
        XCTAssertEqual(countCookies(), 0)
        XCTAssert(app.blockCookiesRequestsRemove(withId: requestId))
        XCTAssertEqual(countCookies(), 1)
    }
}

extension CookiesTest {
    override func setUp() {
        app.launchConnectionless { (path, params) -> String in
            return SBTUITestTunnelServer.performCommand(path, params: params)
        }
    }
}
