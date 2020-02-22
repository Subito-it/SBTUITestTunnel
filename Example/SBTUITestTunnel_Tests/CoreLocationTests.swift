//
//  CoreLocationTests.swift
//  SBTUITestTunnel_Tests
//
//  Created by Egor Komarov on 22.02.2020.
//  Copyright © 2020 Tomas Camin. All rights reserved.
//

import Foundation
import SBTUITestTunnelClient
import XCTest

class CoreLocationTests: XCTestCase {

    func testCoreLocationStubAuthorizationStatus() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)
        XCTAssertEqual(getStubbedCoreLocationAuthorizationStatus(), .authorizedAlways)

        app.coreLocationStubAuthorizationStatus(.notDetermined)
        XCTAssertEqual(getStubbedCoreLocationAuthorizationStatus(), .notDetermined)

        app.coreLocationStubAuthorizationStatus(.denied)
        XCTAssertEqual(getStubbedCoreLocationAuthorizationStatus(), .denied)
        
        app.coreLocationStubAuthorizationStatus(.restricted)
        XCTAssertEqual(getStubbedCoreLocationAuthorizationStatus(), .restricted)

        app.coreLocationStubAuthorizationStatus(.authorizedWhenInUse)
        XCTAssertEqual(getStubbedCoreLocationAuthorizationStatus(), .authorizedWhenInUse)

        app.coreLocationStubAuthorizationStatus(.authorizedAlways)
        XCTAssertEqual(getStubbedCoreLocationAuthorizationStatus(), .authorizedAlways)
    }

    
    private func getStubbedCoreLocationAuthorizationStatus() -> CLAuthorizationStatus {
        let statusString = app.performCustomCommandNamed("myCustomCommandReturnCLAuthStatus", object: nil) as! String
        return CLAuthorizationStatus(rawValue: Int32(statusString)!)!
    }

}
