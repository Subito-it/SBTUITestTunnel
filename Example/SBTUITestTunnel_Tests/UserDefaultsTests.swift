//
//  UserDefaultsTests.swift
//  SBTUITestTunnel
//
//  Created by Tomas on 14/09/16.
//  Copyright © 2016 Tomas Camin. All rights reserved.
//

import SBTUITestTunnel
import Foundation

class UserDefaultsTest: XCTestCase {
    
    var app: SBTUITunneledApplication = SBTUITunneledApplication()

    override func setUp() {
        super.setUp()
        
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem])
        
        expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.tables)
        waitForExpectations(timeout: 15.0, handler: nil)
    }
    
    func testUserDefaultsCommands() {
        let randomString = ProcessInfo.processInfo.globallyUniqueString
        
        let userDefaultKey = "test_key"
        // add and retrieve random string
        XCTAssertTrue(app.userDefaultsSetObject(randomString as NSCoding & NSObjectProtocol, forKey: userDefaultKey))
        XCTAssertEqual(randomString, app.userDefaultsObject(forKey: userDefaultKey) as! String)
        
        // remove and check for nil
        XCTAssertTrue(app.userDefaultsRemoveObject(forKey:userDefaultKey))
        XCTAssertNil(app.userDefaultsObject(forKey: userDefaultKey))
        
        // add again, remove all keys and check for nil item
        XCTAssertTrue(app.userDefaultsSetObject(randomString as NSCoding & NSObjectProtocol, forKey: userDefaultKey))
        app.userDefaultsReset()
        XCTAssertNil(app.userDefaultsObject(forKey: userDefaultKey))
    }
}
