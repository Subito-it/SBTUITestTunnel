// CoreLocationTests.swift
//
// Copyright (C) 2025 Subito.it S.r.l (www.subito.it)
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

import Foundation
import SBTUITestTunnelClient
import XCTest

class CoreLocationTests: XCTestCase {
    func testCoreLocationStubAuthorizationStatus() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)
        XCTAssertEqual(getStubbedCoreLocationAuthorizationStatus(), .authorizedAlways)

        app.tables.cells["showCoreLocationViewController"].tap()
        wait { self.app.staticTexts["location_status"].label == "-" }

        app.coreLocationStubAuthorizationStatus(.notDetermined)
        XCTAssertEqual(getStubbedCoreLocationAuthorizationStatus(), .notDetermined)
        wait { self.app.staticTexts["location_status"].label == "notDetermined" }

        app.coreLocationStubAuthorizationStatus(.denied)
        XCTAssertEqual(getStubbedCoreLocationAuthorizationStatus(), .denied)
        wait { self.app.staticTexts["location_status"].label == "denied" }

        app.coreLocationStubAuthorizationStatus(.restricted)
        XCTAssertEqual(getStubbedCoreLocationAuthorizationStatus(), .restricted)
        wait { self.app.staticTexts["location_status"].label == "restricted" }

        app.coreLocationStubAuthorizationStatus(.authorizedWhenInUse)
        XCTAssertEqual(getStubbedCoreLocationAuthorizationStatus(), .authorizedWhenInUse)
        wait { self.app.staticTexts["location_status"].label == "authorizedWhenInUse" }

        app.coreLocationStubAuthorizationStatus(.authorizedAlways)
        XCTAssertEqual(getStubbedCoreLocationAuthorizationStatus(), .authorizedAlways)
        wait { self.app.staticTexts["location_status"].label == "authorizedAlways" }
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

    func testCoreLocationUpdateRespectsAuthorizationStatus() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)

        app.tables.cells["showCoreLocationViewController"].tap()
        app.buttons["Update location"].tap()

        XCTContext.runActivity(named: "Without authorization no location update should occurr") { _ in
            for status in [CLAuthorizationStatus.notDetermined, .denied, .notDetermined, .restricted] {
                app.coreLocationStubAuthorizationStatus(status)
                app.coreLocationNotifyLocationUpdate([CLLocation(latitude: 44.0, longitude: 11.1)])
                Thread.sleep(forTimeInterval: 1.0)
                XCTAssertEqual(app.staticTexts["location_pos"].label, "-", "Unexpected update with status \(status)")
                XCTAssertEqual(app.staticTexts["location_status_thread"].label, "Main", "Unexpected status update on Not main thread")
            }
        }

        XCTContext.runActivity(named: "With authorization location update should occurr") { _ in
            var statusIndex = 0.0
            for status in [CLAuthorizationStatus.authorizedAlways, .authorizedWhenInUse] {
                app.coreLocationStubAuthorizationStatus(status)
                app.coreLocationNotifyLocationUpdate([CLLocation(latitude: 44.0, longitude: 11.1 + statusIndex)])

                wait(withTimeout: 2) {
                    self.app.staticTexts["location_pos"].label == "44.0 \(11.1 + statusIndex)"
                }

                XCTAssertEqual(app.staticTexts["location_thread"].label, "Main", "Unexpected location update on Not main thread")
                XCTAssertEqual(app.staticTexts["location_status_thread"].label, "Main", "Unexpected status update on Not main thread")

                statusIndex += 1.0
            }
        }
    }

    func testCoreLocationManagerLocationRespectsAuthorizationStatus() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)

        app.tables.cells["showCoreLocationViewController"].tap()

        XCTContext.runActivity(named: "Without authorization no location update should be returned") { _ in
            for status in [CLAuthorizationStatus.notDetermined, .denied, .notDetermined, .restricted] {
                app.coreLocationStubAuthorizationStatus(status)

                app.buttons["Get manager current location"].tap()

                Thread.sleep(forTimeInterval: 1.0)
                XCTAssertEqual(app.staticTexts["manager_location"].label, "nil", "Unexpected location with status \(status)")
            }
        }

        XCTContext.runActivity(named: "With authorization location update should occurr") { _ in
            var statusIndex = 0.0
            for status in [CLAuthorizationStatus.authorizedAlways, .authorizedWhenInUse] {
                app.coreLocationStubAuthorizationStatus(status)
                app.coreLocationStubManagerLocation(CLLocation(latitude: 44.0, longitude: 11.1 + statusIndex))

                app.buttons["Get manager current location"].tap()

                wait(withTimeout: 2) {
                    self.app.staticTexts["manager_location"].label == "44.0 \(11.1 + statusIndex)"
                }

                statusIndex += 1.0
            }
        }

        XCTContext.runActivity(named: "Check that nil location is supported") { _ in
            app.coreLocationStubAuthorizationStatus(.authorizedAlways)
            app.coreLocationStubManagerLocation(nil)

            app.buttons["Get manager current location"].tap()

            wait(withTimeout: 2) {
                self.app.staticTexts["manager_location"].label == "nil"
            }
        }

        XCTContext.runActivity(named: "Check that non nil location updates") { _ in
            app.coreLocationStubAuthorizationStatus(.authorizedAlways)
            app.coreLocationStubManagerLocation(CLLocation(latitude: 44.0, longitude: 11.1))

            app.buttons["Get manager current location"].tap()

            wait(withTimeout: 2) {
                self.app.staticTexts["manager_location"].label == "44.0 \(11.1)"
            }
        }
    }

    func testCoreLocationManagerLocationGetsUpdatedOnLocationUpdates() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)
        app.coreLocationStubAuthorizationStatus(.authorizedAlways)

        app.tables.cells["showCoreLocationViewController"].tap()

        app.buttons["Get manager current location"].tap()
        wait(withTimeout: 2) {
            self.app.staticTexts["manager_location"].label == "nil"
        }

        app.coreLocationNotifyLocationUpdate([CLLocation(latitude: 44.0, longitude: 11.1)])

        app.buttons["Get manager current location"].tap()
        wait(withTimeout: 2) {
            self.app.staticTexts["manager_location"].label == "44.0 \(11.1)"
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
