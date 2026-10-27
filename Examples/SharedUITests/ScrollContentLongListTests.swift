// ScrollContentLongListTests.swift
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
class ScrollContentLongListTests: XCTestCase {
    override func setUp() {
        super.setUp()
        app.launchArguments.append("--long-scroll-list")
        app.launchTunnel()
        openTestSection(identifier: "showExtensionTable1")
        XCTAssertTrue(app.scrollTableView(withIdentifier: "table", toRowIndex: 5000, animated: false))
    }

    override func tearDown() {
        app.launchArguments.removeAll { $0 == "--long-scroll-list" }
        super.tearDown()
    }

    func testLegacyIdentifierSearchStartsAtCurrentPosition() {
        // Restarting this 10,000-row list at row zero exhausts the search timeout.
        XCTAssertTrue(app.scrollTableView(withIdentifier: "table", toElementWithIdentifier: "label_5020", animated: false))
        XCTAssertTrue(app.staticTexts["Label 5020"].isHittable)
    }

    func testUnifiedIdentifierSearchStartsAtCurrentPosition() {
        XCTAssertTrue(app.scrollContent(withIdentifier: "table", toElementWithIdentifier: "label_5020", animated: false))
        XCTAssertTrue(app.staticTexts["Label 5020"].isHittable)
    }

    func testIdentifierSearchReservesTimeForEarlierRows() {
        // The forward pass cannot reach the end in time; wrapping must still
        // leave time to find earlier cells that UIKit has discarded.
        XCTAssertTrue(app.scrollTableView(withIdentifier: "table", toElementWithIdentifier: "label_3", animated: false))
        XCTAssertTrue(app.staticTexts["Label 3"].isHittable)
    }
}
#endif
