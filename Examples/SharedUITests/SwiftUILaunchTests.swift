// SwiftUILaunchTests.swift
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

#if SWIFTUI_APP
    import SBTUITestTunnelClient
    import XCTest

    final class SwiftUILaunchTests: XCTestCase {
        func testStartupCommandsCompleteBeforeInitialViewReadsDefaults() {
            let value = UUID().uuidString
            app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem]) {
                self.app.userDefaultsSetObject(value as NSString, forKey: "swiftui_launch_injected_value")
            }

            let initialValue = app.staticTexts["launch_injected_value"]
            XCTAssertTrue(initialValue.waitForExistence(timeout: 5))
            XCTAssertEqual(initialValue.label, value)

            // The fixture captures defaults when ContentView is constructed.
            // A later tunnel write must not make an incorrectly ordered launch pass.
            app.userDefaultsSetObject("later" as NSString, forKey: "swiftui_launch_injected_value")
            XCTAssertEqual(initialValue.label, value)

            app.terminate()
            let secondValue = UUID().uuidString
            app.launchTunnel {
                self.app.userDefaultsSetObject(secondValue as NSString, forKey: "swiftui_launch_injected_value")
            }
            XCTAssertEqual(initialValue.label, secondValue)
        }

        func testSwiftUIAppLaunchesWithoutTunnel() {
            app.launch()
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "example_list").firstMatch.waitForExistence(timeout: 5))
        }
    }
#endif
