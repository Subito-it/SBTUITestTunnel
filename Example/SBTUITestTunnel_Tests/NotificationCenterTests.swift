//
//  NotificationCenterTests.swift
//  SBTUITestTunnel_Tests
//
//  Created by Alvar Hansen on 08.10.2021.
//  Copyright © 2021 Tomas Camin. All rights reserved.
//

import Foundation
import SBTUITestTunnelClient
import XCTest

class NotificationCenterTests: XCTestCase {

    func testNotificationCenterStubAuthorizationRequestDefaultStatus() {
        app.launchTunnel()
        app.notificationCenterStubEnabled(true)

        XCTAssertEqual(getStubbedNotificationCenterAuthorizationRequest(), true)
    }

    func testNotificationCenterStubAuthorizationRequestDeniedStatus() {
        app.launchTunnel()
        app.notificationCenterStubEnabled(true)

        app.notificationCenterStubAuthorizationStatus(.denied)
        XCTAssertEqual(getStubbedNotificationCenterAuthorizationRequest(), false)
    }

    func testNotificationCenterStubAuthorizationStatus() {
        app.launchTunnel()
        app.notificationCenterStubEnabled(true)

        XCTAssertEqual(getStubbedNotificationCenterAuthorizationStatus(), .authorized)

        app.notificationCenterStubAuthorizationStatus(.denied)
        XCTAssertEqual(getStubbedNotificationCenterAuthorizationStatus(), .denied)
    }


    private func getStubbedNotificationCenterAuthorizationRequest() -> Bool {
        let statusString = app.performCustomCommandNamed("myCustomCommandReturnUNAuthRequest", object: nil) as! String
        return Int(statusString) == 1
    }

    private func getStubbedNotificationCenterAuthorizationStatus() -> UNAuthorizationStatus {
        let statusString = app.performCustomCommandNamed("myCustomCommandReturnUNAuthStatus", object: nil) as! String
        return UNAuthorizationStatus(rawValue: Int(statusString)!)!
    }
}
