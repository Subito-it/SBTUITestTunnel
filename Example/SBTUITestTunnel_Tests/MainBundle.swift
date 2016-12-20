// MainBundle.swift
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

class MainBundleTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem])
        
        expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.tables)
        waitForExpectations(timeout: 15.0, handler: nil)
        
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    func testMainBundleInfoDictionary() {
        guard let infoDictionary = app.mainBundleInfoDictionary() else {
            XCTFail("failed to deserialize info dictionary")
            return
        }
        
        XCTAssertEqual((infoDictionary["CFBundleIdentifier"] as? String) ?? "", "com.tomascamin.SBTUITestTunnel-Example")
        XCTAssertEqual((infoDictionary["CFBundleVersion"] as? String) ?? "", "1.0")
        XCTAssertEqual((infoDictionary["MinimumOSVersion"] as? String) ?? "", "8.0")
    }
}
