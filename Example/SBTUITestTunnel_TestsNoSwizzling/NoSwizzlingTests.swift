// NoSwizzlingTests.swift
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

import SBTUITestTunnelClient
import Foundation
import XCTest


class NoSwizzlingTests: XCTestCase {

    let app = MyCustomApplication()

    override func setUp() {
        super.setUp()

        app.launchTunnel()

        expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.tables)
        waitForExpectations(timeout: 15.0, handler: nil)

        Thread.sleep(forTimeInterval: 1.0)
    }
    
    func testShutdown() {
        app.terminate()
        XCTAssert(app.wait(for: .notRunning, timeout: 5))

        app.launchTunnel()
        XCTAssert(app.wait(for: .runningForeground, timeout: 5))
        
        expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.tables)
        waitForExpectations(timeout: 15.0, handler: nil)
    }
}

class MyCustomApplication: XCUIApplication {
    lazy var client: SBTUITestTunnelClient = {
        let client = SBTUITestTunnelClient(application: self)
        client.delegate = self
        return client
    }()
    
    func launchTunnel() {
        // Do any custom launch things
        client.launchTunnel()
    }
    
    override func terminate() {
        // Do any custom tidy up things
        client.terminate()
    }
}

extension MyCustomApplication: SBTUITestTunnelClientDelegate {
    func testTunnelClientIsReady(toLaunch sender: SBTUITestTunnelClient) {
        // Call the XCUIApplication.lanuch() method
        launch()
    }
    
    func testTunnelClient(_ sender: SBTUITestTunnelClient, didShutdownWithError error: Error?) {
        // optionally handle errors
        print(String(describing: error?.localizedDescription))
        
        // Call the XCUIApplication.terminate() method
        super.terminate()
    }
}
