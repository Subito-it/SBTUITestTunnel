// AsyncTests.swift
//
// Copyright (C) 2026 Subito.it S.r.l (www.subito.it)
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
import XCTest

final class AsyncTests: XCTestCase {
    @MainActor
    func testLaunchWithoutStartupCommands() async throws {
        // Resume the test on the main actor after a suspension before launching.
        try await Task.sleep(nanoseconds: 1_000_000)

        app.launchTunnel()

        XCTAssertTrue(app.userDefaultsSetObject("ready" as NSString, forKey: "async_launch_value"))
        XCTAssertEqual(app.userDefaultsObject(forKey: "async_launch_value") as? String, "ready")
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "example_list").firstMatch.exists)
    }

    @MainActor
    func testStartupCommands() async {
        let value = UUID().uuidString
        let key = "swiftui_launch_injected_value"
        var startupCalls = 0

        app.launchTunnel {
            XCTAssertTrue(Thread.isMainThread)
            startupCalls += 1
            XCTAssertTrue(self.app.userDefaultsSetObject(value as NSString, forKey: key))
            XCTAssertTrue(self.app.setUserInterfaceAnimationsEnabled(false))
        }

        XCTAssertEqual(startupCalls, 1)
        XCTAssertEqual(app.userDefaultsObject(forKey: key) as? String, value)

        #if SWIFTUI_APP
            // The initial view captures this value at construction, before any
            // post-launch tunnel command could correct a late startup block.
            XCTAssertEqual(app.staticTexts["launch_injected_value"].label, value)
        #endif

        await Task.yield()

        XCTAssertEqual(app.userDefaultsObject(forKey: key) as? String, value)
    }

    @MainActor
    func testRelaunchAfterSuspension() async throws {
        let key = "async_relaunch_value"
        let value = UUID().uuidString
        var startupCalls = 0

        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem]) {
            startupCalls += 1
            XCTAssertTrue(self.app.userDefaultsSetObject(value as NSString, forKey: key))
        }
        XCTAssertEqual(startupCalls, 1)
        XCTAssertEqual(app.userDefaultsObject(forKey: key) as? String, value)
        app.terminate()

        try await Task.sleep(nanoseconds: 1_000_000)

        app.launchTunnel {
            XCTAssertTrue(Thread.isMainThread)
            startupCalls += 1
            XCTAssertTrue(self.app.userDefaultsSetObject("relaunched" as NSString, forKey: key))
        }

        XCTAssertEqual(startupCalls, 2)
        XCTAssertEqual(app.userDefaultsObject(forKey: key) as? String, "relaunched")
    }
}
