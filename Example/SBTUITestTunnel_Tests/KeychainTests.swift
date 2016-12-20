// KeychainTests.swift
//
// Copyright (C) 2016 Subito.it S.r.l (www.subito.it)
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

import SBTUITestTunnel
import Foundation

class KeychainTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem])
        
        expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.tables)
        waitForExpectations(timeout: 15.0, handler: nil)
        
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    func testKeychain() {
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
