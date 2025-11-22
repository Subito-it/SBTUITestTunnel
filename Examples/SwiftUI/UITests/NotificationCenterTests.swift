// NotificationCenterTests.swift
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
