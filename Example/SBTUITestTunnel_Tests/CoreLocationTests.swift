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
    
    func testCoreLocationUpdate() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)
        XCTAssertEqual(getStubbedCoreLocationAuthorizationStatus(), .authorizedAlways)

        app.tables.cells["showCoreLocationViewController"].tap()
        app.buttons["Update location"].tap()
        
        app.coreLocationNotifyLocationUpdate([CLLocation(latitude: 44.0, longitude: 11.1)])
        
        wait { self.app.staticTexts["location_pos"].label == "44.0 11.1" }
        
        app.navigationBars.buttons.firstMatch.tap()
        
        Thread.sleep(forTimeInterval: 2.0)
        
        app.coreLocationNotifyLocationUpdate([CLLocation(latitude: 44.0, longitude: 11.1)])
    }

    func testCoreLocationStopAndResume() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)
        XCTAssertEqual(getStubbedCoreLocationAuthorizationStatus(), .authorizedAlways)

        app.tables.cells["showCoreLocationViewController"].tap()
        app.buttons["Update location"].tap()

        app.coreLocationNotifyLocationUpdate([CLLocation(latitude: 44.0, longitude: 11.1)])

        wait { self.app.staticTexts["location_pos"].label == "44.0 11.1" }
        wait { self.app.staticTexts["location_thread"].label == "Main" }

        app.buttons["Stop location updates"].tap()
        app.coreLocationNotifyLocationUpdate([CLLocation(latitude: 0.0, longitude: 0.0)])
        Thread.sleep(forTimeInterval: 2.0)
        wait { self.app.staticTexts["location_pos"].label == "44.0 11.1" }
        wait { self.app.staticTexts["location_thread"].label == "Main" }

        app.buttons["Update location"].tap()

        app.coreLocationNotifyLocationUpdate([CLLocation(latitude: 11.1, longitude: 44.0)])

        wait(withTimeout: 2) {
            self.app.staticTexts["location_pos"].label == "11.1 44.0" &&
            self.app.staticTexts["location_thread"].label == "Main"
        }
    }
    
    @available(iOS 14, *)
    func testCoreLocationStubAccuracyAuthorization() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)

        app.coreLocationStubAccuracyAuthorization(.fullAccuracy)
        XCTAssertEqual(getStubbedCoreLocationAccuracyAuthorization(), .fullAccuracy)

        app.coreLocationStubAccuracyAuthorization(.reducedAccuracy)
        XCTAssertEqual(getStubbedCoreLocationAccuracyAuthorization(), .reducedAccuracy)
    }
    
    private func getStubbedCoreLocationAuthorizationStatus() -> CLAuthorizationStatus {
        let statusString = app.performCustomCommandNamed("myCustomCommandReturnCLAuthStatus", object: nil) as! String
        return CLAuthorizationStatus(rawValue: Int32(statusString)!)!
    }
    
    @available(iOS 14, *)
    private func getStubbedCoreLocationAccuracyAuthorization() -> CLAccuracyAuthorization {
        let statusString = app.performCustomCommandNamed("myCustomCommandReturnCLAccuracyAuth", object: nil) as! String
        return CLAccuracyAuthorization(rawValue: Int(statusString)!)!
    }
}
