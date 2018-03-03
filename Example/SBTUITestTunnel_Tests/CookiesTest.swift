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
    
    func testCookiesGetBlocked() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        app.blockCookiesInRequests(matching: requestMatch)
        _ = request.dataTaskNetwork(urlString: "http://httpbin.org/cookies/set?name=value")
        
        XCTAssertEqual(HTTPCookieStorage.shared.cookies!.count, 0)
    }
}

extension CookiesTest {
    override func setUp() {
        app.launchConnectionless { (path, params) -> String in
            return SBTUITestTunnelServer.performCommand(path, params: params)
        }
    }
    
    override func tearDown() {
        app.monitorRequestRemoveAll()
        app.stubRequestsRemoveAll()
        app.blockCookiesRequestsRemoveAll()
        app.throttleRequestRemoveAll()
    }
}
