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
    var coreLocationCell: String { "showCoreLocationViewController" }
    var managerThread: String { "Main" }

    func testCoreLocationStubAuthorizationStatus() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)

        app.tables.cells[coreLocationCell].tap()
        wait { self.app.staticTexts["location_status"].label == "authorizedAlways" }

        let statuses: [(CLAuthorizationStatus, String)] = [
            (.notDetermined, "notDetermined"),
            (.denied, "denied"),
            (.restricted, "restricted"),
            (.authorizedWhenInUse, "authorizedWhenInUse"),
            (.authorizedAlways, "authorizedAlways"),
        ]

        for (status, statusDescription) in statuses {
            app.coreLocationStubAuthorizationStatus(status)
            XCTAssertEqual(getStubbedCoreLocationAuthorizationStatus(), status)
            wait {
                self.app.staticTexts["location_status"].label == statusDescription &&
                    self.app.staticTexts["location_pre_ios14_deprecated_delegate_status"].label == statusDescription
            }
            XCTAssertEqual(app.staticTexts["location_status_thread"].label, managerThread)
        }
    }

    func testCoreLocationUpdate() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)
        XCTAssertEqual(getStubbedCoreLocationAuthorizationStatus(), .authorizedAlways)

        app.tables.cells[coreLocationCell].tap()
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

        app.tables.cells[coreLocationCell].tap()
        app.buttons["Update location"].tap()

        app.coreLocationNotifyLocationUpdate([CLLocation(latitude: 44.0, longitude: 11.1)])

        wait { self.app.staticTexts["location_pos"].label == "44.0 11.1" }
        wait { self.app.staticTexts["location_thread"].label == self.managerThread }

        app.buttons["Stop location updates"].tap()
        app.coreLocationNotifyLocationUpdate([CLLocation(latitude: 0.0, longitude: 0.0)])
        Thread.sleep(forTimeInterval: 2.0)
        wait { self.app.staticTexts["location_pos"].label == "44.0 11.1" }
        wait { self.app.staticTexts["location_thread"].label == self.managerThread }

        app.buttons["Update location"].tap()

        app.coreLocationNotifyLocationUpdate([CLLocation(latitude: 11.1, longitude: 44.0)])

        wait(withTimeout: 2) {
            self.app.staticTexts["location_pos"].label == "11.1 44.0" &&
                self.app.staticTexts["location_thread"].label == self.managerThread
        }
    }

    func testCoreLocationUpdateRespectsAuthorizationStatus() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)

        app.tables.cells[coreLocationCell].tap()
        app.buttons["Update location"].tap()

        XCTContext.runActivity(named: "Without authorization no location update should occurr") { _ in
            for status in [CLAuthorizationStatus.notDetermined, .denied, .notDetermined, .restricted] {
                app.coreLocationStubAuthorizationStatus(status)
                app.coreLocationNotifyLocationUpdate([CLLocation(latitude: 44.0, longitude: 11.1)])
                Thread.sleep(forTimeInterval: 1.0)
                XCTAssertEqual(app.staticTexts["location_pos"].label, "-", "Unexpected update with status \(status)")
                XCTAssertEqual(app.staticTexts["location_status_thread"].label, managerThread, "Unexpected status update thread")
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

                XCTAssertEqual(app.staticTexts["location_thread"].label, managerThread, "Unexpected location update thread")
                XCTAssertEqual(app.staticTexts["location_status_thread"].label, managerThread, "Unexpected status update thread")

                statusIndex += 1.0
            }
        }
    }

    func testCoreLocationManagerLocationRespectsAuthorizationStatus() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)

        app.tables.cells[coreLocationCell].tap()

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

        app.tables.cells[coreLocationCell].tap()

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

    func testCoreLocationPreIOS14DeprecatedDelegateReceivesStubbedAuthorizationStatusOnInit() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)
        app.coreLocationStubAuthorizationStatus(.denied)

        app.tables.cells[coreLocationCell].tap()

        // The pre-iOS 14 deprecated locationManager:didChangeAuthorizationStatus:
        // delegate method must receive the stubbed status (denied) on the initial
        // delegate invocation, not the device's actual authorization status.
        wait { self.app.staticTexts["location_pre_ios14_deprecated_delegate_status"].label == "denied" }
    }

    @available(iOS 14, *)
    func testCoreLocationStubAccuracyAuthorization() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)

        app.tables.cells[coreLocationCell].tap()
        wait { self.app.staticTexts["location_accuracy"].label == "fullAccuracy" }

        app.coreLocationStubAccuracyAuthorization(.reducedAccuracy)
        XCTAssertEqual(getStubbedCoreLocationAccuracyAuthorization(), .reducedAccuracy)
        wait { self.app.staticTexts["location_accuracy"].label == "reducedAccuracy" }
        XCTAssertEqual(app.staticTexts["location_status_thread"].label, managerThread)

        app.coreLocationStubAccuracyAuthorization(.fullAccuracy)
        XCTAssertEqual(getStubbedCoreLocationAccuracyAuthorization(), .fullAccuracy)
        wait { self.app.staticTexts["location_accuracy"].label == "fullAccuracy" }
        XCTAssertEqual(app.staticTexts["location_status_thread"].label, managerThread)
    }

    func testCoreLocationNotifyLocationError() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)

        app.tables.cells[coreLocationCell].tap()
        app.buttons["Update location"].tap()

        app.coreLocationNotifyLocationError(NSError(domain: kCLErrorDomain, code: CLError.Code.network.rawValue))

        wait {
            self.app.staticTexts["location_error"].label == "\(kCLErrorDomain) \(CLError.Code.network.rawValue)" &&
                self.app.staticTexts["location_error_thread"].label == self.managerThread
        }
    }

    func testCoreLocationManagerCreatedBeforeStubbingIsNotifiedOnMainThread() {
        app.launchTunnel()

        app.tables.cells[coreLocationCell].tap()

        // The manager predates the init swizzle, so its creation thread is unknown and delivery falls back to main
        app.coreLocationStubEnabled(true)
        app.performCustomCommandNamed("coreLocationFixture", object: "reassignDelegate")
        app.coreLocationNotifyLocationUpdate([CLLocation(latitude: 44.0, longitude: 11.1)])

        wait {
            self.app.staticTexts["location_pos"].label == "44.0 11.1" &&
                self.app.staticTexts["location_thread"].label == "Main"
        }
    }

    func testCoreLocationQueuedUpdateIsDroppedWhenDelegateIsCleared() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)

        app.tables.cells[coreLocationCell].tap()
        app.buttons["Update location"].tap()

        app.performCustomCommandNamed("coreLocationFixture", object: "holdThenClearDelegate")
        app.coreLocationNotifyLocationUpdate([CLLocation(latitude: 44.0, longitude: 11.1)])
        app.performCustomCommandNamed("coreLocationFixture", object: "releaseManagerThread")

        XCTAssertEqual(app.staticTexts["location_pos"].label, "-")
    }

    func testCoreLocationQueuedUpdateReachesReplacementDelegate() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)

        app.tables.cells[coreLocationCell].tap()
        app.buttons["Update location"].tap()

        app.performCustomCommandNamed("coreLocationFixture", object: "holdThenReplaceDelegate")
        app.coreLocationNotifyLocationUpdate([CLLocation(latitude: 44.0, longitude: 11.1)])
        app.performCustomCommandNamed("coreLocationFixture", object: "releaseManagerThread")

        XCTAssertEqual(app.staticTexts["location_pos"].label, "replacement 44.0 11.1")
    }

    func testCoreLocationDelegateClearedByLegacyAuthorizationCallbackSkipsModernCallback() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)

        app.tables.cells[coreLocationCell].tap()
        wait {
            self.app.staticTexts["location_status"].label == "authorizedAlways" &&
                self.app.staticTexts["location_pre_ios14_deprecated_delegate_status"].label == "authorizedAlways"
        }

        app.performCustomCommandNamed("coreLocationFixture", object: "clearDelegateOnLegacyAuthorizationCallback")
        app.coreLocationStubAuthorizationStatus(.denied)
        app.performCustomCommandNamed("coreLocationFixture", object: "waitForQueuedCallbacks")

        XCTAssertEqual(app.staticTexts["location_pre_ios14_deprecated_delegate_status"].label, "denied")
        XCTAssertEqual(app.staticTexts["location_status"].label, "authorizedAlways")
    }

    func testCoreLocationInitialAuthorizationIsDroppedWhenDelegateIsClearedBeforeDelivery() {
        app.launchTunnel()

        app.coreLocationStubEnabled(true)

        app.tables.cells[coreLocationCell].tap()
        wait {
            self.app.staticTexts["location_status"].label == "authorizedAlways" &&
                self.app.staticTexts["location_pre_ios14_deprecated_delegate_status"].label == "authorizedAlways"
        }

        // Unregistered, so the delegate isn't told about the new status
        app.performCustomCommandNamed("coreLocationFixture", object: "clearDelegate")
        app.coreLocationStubAuthorizationStatus(.denied)

        app.performCustomCommandNamed("coreLocationFixture", object: "assignThenClearDelegate")
        XCTAssertEqual(app.staticTexts["location_status"].label, "authorizedAlways")
        XCTAssertEqual(app.staticTexts["location_pre_ios14_deprecated_delegate_status"].label, "authorizedAlways")

        app.performCustomCommandNamed("coreLocationFixture", object: "reassignDelegate")
        wait {
            self.app.staticTexts["location_status"].label == "denied" &&
                self.app.staticTexts["location_pre_ios14_deprecated_delegate_status"].label == "denied"
        }
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

final class CoreLocationBackgroundThreadTests: CoreLocationTests {
    override var coreLocationCell: String { "showCoreLocationViewControllerOnBackgroundThread" }
    override var managerThread: String { "Background" }
}
