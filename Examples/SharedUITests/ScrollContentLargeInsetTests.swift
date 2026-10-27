// ScrollContentLargeInsetTests.swift
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

#if UIKIT_APP
class ScrollContentLargeInsetTests: XCTestCase {
    override func setUp() {
        super.setUp()
        app.launchArguments.append("--large-bottom-inset")
        app.launchTunnel()
        openTestSection(identifier: "showExtensionTable1")
        wait { self.app.staticTexts["Label 0"].isHittable }
    }

    override func tearDown() {
        app.launchArguments.removeAll { $0 == "--large-bottom-inset" }
        super.tearDown()
    }

    func testScrollToEndPagesThroughContentInset() {
        XCTAssertTrue(app.scrollContentToEnd(withIdentifier: "table", animated: false))
        XCTAssertTrue(app.staticTexts["Label 99"].isHittable)
    }
}
#endif
