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
        
    override func setUp() {
        super.setUp()
        
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem])
        
        expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.tables)
        waitForExpectations(timeout: 15.0, handler: nil)
        
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    func testCookies() {
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        app.monitorRequests(matching: requestMatch)
        //app.blockCookiesInRequests(matching: requestMatch)
        
        app.cells["executeRequestWithCookies"].tap()
        
        XCTAssert(app.waitForMonitoredRequests(matching: requestMatch, timeout: 5.0))
        let monitoredRequests = app.monitoredRequestsFlushAll()
        for monitoredRequest in monitoredRequests {
            for cookie in HTTPCookieStorage.shared.cookies! {
                print("EXTRACTED COOKIE: \(cookie)") //find your cookie here instead of httpUrlResponse.allHeaderFields
            }
            
            print(monitoredRequest.request?.allHTTPHeaderFields)
        }
        
        
        app.cells["executeRequestWithCookies"].tap()
        app.cells["executeRequestWithCookies"].tap()
        app.cells["executeRequestWithCookies"].tap()
        app.cells["executeRequestWithCookies"].tap()
        
        Thread.sleep(forTimeInterval: 50.0)
    }
}
