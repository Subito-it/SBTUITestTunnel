//
//  CookiesTest.swift
//  SBTUITestTunnel_Tests
//
//  Created by Tomas Camin on 06/02/2018.
//  Copyright © 2018 Tomas Camin. All rights reserved.
//

import Foundation
import SBTUITestTunnelClient
import SBTUITestTunnelServer
import XCTest

class CookiesTest: XCTestCase {
    private let request = NetworkRequests()
    
    private func countCookies() -> Int {
        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/cookies")
        let json = request.json(result)
        
        return (json["cookies"] as? [String: Any])?.keys.count ?? 0
    }
    
    func testCookiesGetBlocked() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/cookies/set?name=value") // set a random cookie
        
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        app.blockCookiesInRequests(matching: requestMatch)
        
        XCTAssertEqual(countCookies(), 0)
    }
    
    func testBlockCookiesAndRemove() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/cookies/set?name=value") // set a random cookie
        
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        app.blockCookiesInRequests(matching: requestMatch, activeIterations: 1)
        XCTAssertEqual(countCookies(), 0)
        XCTAssertEqual(countCookies(), 1)
    }
    
    func testBlockCookiesAndRemoveAll() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/cookies/set?name=value") // set a random cookie
        
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        app.blockCookiesInRequests(matching: requestMatch)
        XCTAssertEqual(countCookies(), 0)
        XCTAssert(app.blockCookiesRequestsRemoveAll())
        XCTAssertEqual(countCookies(), 1)
    }
    
    func testBlockCookiesAndRemoveSpecific() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/cookies/set?name=value") // set a random cookie
        
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        let requestId = app.blockCookiesInRequests(matching: requestMatch) ?? ""
        XCTAssertEqual(countCookies(), 0)
        XCTAssert(app.blockCookiesRequestsRemove(withId: requestId))
        XCTAssertEqual(countCookies(), 1)
    }

    func testMultipleBlockCookiesForSameRequestMatch() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        _ = request.dataTaskNetwork(urlString: "https://httpbin.org/cookies/set?name=value") // set a random cookie
                
        XCTContext.runActivity(named: "When adding multiple block cookies for the same requests match") { _ in
            let requestMatch = SBTRequestMatch(url: "httpbin.org")
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
        SBTUITestTunnelServer.perform(NSSelectorFromString("_connectionlessReset"))
        app.launchConnectionless { (path, params) -> String in
            SBTUITestTunnelServer.performCommand(path, params: params)
        }
    }
}
