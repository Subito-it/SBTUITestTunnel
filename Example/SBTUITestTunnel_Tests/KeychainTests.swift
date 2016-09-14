//
//  KeychainTests.swift
//  SBTUITestTunnel
//
//  Created by Tomas on 15/09/16.
//  Copyright © 2016 Tomas Camin. All rights reserved.
//

import SBTUITestTunnel
import Foundation

class KeychainTests: XCTestCase {
    
    var app: SBTUITunneledApplication = SBTUITunneledApplication()
    
    override func setUp() {
        super.setUp()
        
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem])
        
        expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.tables)
        waitForExpectations(timeout: 15.0, handler: nil)
    }
    
    func testKeychainCommands() {
        let randomString = ProcessInfo.processInfo.globallyUniqueString
        
        let keychainKey = "test_kc_key"
        // add and retrieve random string
        XCTAssertTrue(app.keychainSetObject(randomString as NSCoding & NSObjectProtocol, forKey: keychainKey))
        XCTAssertEqual(randomString, app.keychainObject(forKey: keychainKey) as! String)
        
        // remove and check for nil
        XCTAssertTrue(app.keychainRemoveObject(forKey:keychainKey))
        XCTAssertNil(app.keychainObject(forKey: keychainKey))
        
        // add again, remove all keys and check for nil item
        XCTAssertTrue(app.keychainSetObject(randomString as NSCoding & NSObjectProtocol, forKey: keychainKey))
        app.keychainReset()
        XCTAssertNil(app.keychainObject(forKey: keychainKey))
    }
}
