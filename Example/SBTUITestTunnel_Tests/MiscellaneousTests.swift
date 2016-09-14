//
//  MiscellaneousTests.swift
//  SBTUITestTunnel
//
//  Created by Tomas on 15/09/16.
//  Copyright © 2016 Tomas Camin. All rights reserved.
//

import SBTUITestTunnel
import Foundation

class MiscellaneousTests: XCTestCase {
    
    var app: SBTUITunneledApplication = SBTUITunneledApplication()
    
    func testStartupCommands() {
        let keychainKey = "test_kc_key"
        let randomString = ProcessInfo.processInfo.globallyUniqueString
        app.launchTunnel() {
            self.app.keychainSetObject(randomString as NSCoding & NSObjectProtocol, forKey: keychainKey)
            self.app.setUserInterfaceAnimationsEnabled(false)
        }
        
        XCTAssertEqual(randomString, app.keychainObject(forKey: keychainKey) as! String)
    }
}
