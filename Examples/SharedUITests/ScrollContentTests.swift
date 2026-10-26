// ScrollContentTests.swift
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

import Foundation
import SBTUITestTunnelClient
import SBTUITestTunnelServer
import XCTest

class ScrollContentTests: XCTestCase {
    override func setUp() {
        super.setUp()
        app.launchTunnel()
    }

    func testScrollContentTableViewToIndex() {
        openTestSection(identifier: "showExtensionTable1")

        wait { self.app.staticTexts["Label 5"].isHittable }
        XCTAssert(app.staticTexts["Label 5"].isHittable)
        XCTAssertFalse(app.staticTexts["Label 99"].isHittable)

        XCTAssert(app.scrollContent(withIdentifier: "table", toElementIndex: 99, animated: false))

        XCTAssertFalse(app.staticTexts["Label 5"].isHittable)
        XCTAssert(app.staticTexts["Label 99"].isHittable)
    }

    func testScrollContentTableViewToOffset() {
        openTestSection(identifier: "showExtensionTable1")

        wait { self.app.staticTexts["Label 4"].isHittable }
        XCTAssert(app.staticTexts["Label 4"].isHittable)
        XCTAssertFalse(app.staticTexts["Label 99"].isHittable)

        XCTAssertTrue(app.scrollContent(withIdentifier: "table", toOffset: 1, animated: false))

        XCTAssertFalse(app.staticTexts["Label 4"].isHittable)
        XCTAssert(app.staticTexts["Label 99"].isHittable)

        XCTAssertTrue(app.scrollContent(withIdentifier: "table", toOffset: 0, animated: false))

        XCTAssert(app.staticTexts["Label 4"].isHittable)
        XCTAssertFalse(app.staticTexts["Label 99"].isHittable)
    }

    func testScrollContentTableViewToIdentifier() {
        openTestSection(identifier: "showExtensionTable1")

        wait { self.app.staticTexts["Label 5"].isHittable }
        XCTAssert(app.staticTexts["Label 5"].isHittable)
        XCTAssertFalse(app.staticTexts["Label 99"].isHittable)

        XCTAssert(app.scrollContent(withIdentifier: "table", toElementWithIdentifier: "label_99", animated: false))

        XCTAssertFalse(app.staticTexts["Label 5"].isHittable)
        XCTAssert(app.staticTexts["Label 99"].isHittable)

        XCTAssert(app.scrollContent(withIdentifier: "table", toOffset: 0, animated: false))
        XCTAssert(app.scrollContent(withIdentifier: "table", toElementWithIdentifier: "label_50", animated: false))

        XCTAssertFalse(app.staticTexts["Label 5"].isHittable)
        XCTAssertFalse(app.staticTexts["Label 99"].isHittable)
        XCTAssert(app.staticTexts["Label 50"].isHittable)
    }

    func testScrollContentCollectionViewVertical() {
        openTestSection(identifier: "showExtensionCollectionViewVertical")

        wait { self.app.buttons["Button 3"].isHittable }
        XCTAssert(app.buttons["Button 3"].isHittable)
        XCTAssertFalse(app.buttons["Button 30"].isHittable)

        XCTAssert(app.scrollContent(withIdentifier: "collection", toElementWithIdentifier: "button_30", animated: true))

        XCTAssertFalse(app.buttons["Button 3"].isHittable)
        XCTAssert(app.buttons["Button 30"].isHittable)
    }

    func testScrollContentCollectionViewHorizontal() {
        openTestSection(identifier: "showExtensionCollectionViewHorizontal")

        wait { self.app.staticTexts["3"].isHittable }
        XCTAssert(app.staticTexts["3"].isHittable)
        XCTAssertFalse(app.staticTexts["30"].isHittable)

        XCTAssert(app.scrollContent(withIdentifier: "collection", toElementWithIdentifier: "label_30", animated: true))

        XCTAssertFalse(app.staticTexts["3"].isHittable)
        XCTAssert(app.staticTexts["30"].isHittable)
    }

    func testScrollContentScrollViewToOffset() {
        openTestSection(identifier: "showExtensionScrollView")

        wait { self.app.scrollViews["scrollView"].staticTexts["Content 0"].isHittable }
        XCTAssert(app.scrollViews["scrollView"].staticTexts["Content 0"].isHittable)
        XCTAssertFalse(app.scrollViews["scrollView"].buttons["Button"].isHittable)

        XCTAssertTrue(app.scrollContent(withIdentifier: "scrollView", toOffset: 0.50, animated: true))

        XCTAssertFalse(app.scrollViews["scrollView"].staticTexts["Content 0"].isHittable)
        XCTAssert(app.scrollViews["scrollView"].staticTexts["Content 19"].isHittable)
        XCTAssert(app.scrollViews["scrollView"].buttons["Button"].isHittable)
        XCTAssert(app.scrollViews["scrollView"].staticTexts["Content 20"].isHittable)
        XCTAssertFalse(app.scrollViews["scrollView"].staticTexts["Content 39"].isHittable)

        XCTAssertTrue(app.scrollContent(withIdentifier: "scrollView", toOffset: 0.0, animated: true))
        XCTAssertFalse(app.scrollViews["scrollView"].buttons["Button"].isHittable)
    }

    func testScrollContentDirectClient() throws {
        openTestSection(identifier: "showExtensionTable1")

        // Exercise the protocol on the connected client itself, independently
        // of the application forwarding methods.
        let client = try XCTUnwrap(app.value(forKey: "client") as? SBTUITestTunnelClient)
        XCTAssertTrue(client.scrollContent(withIdentifier: "table", toElementIndex: 99, animated: false))
        XCTAssert(app.staticTexts["Label 99"].isHittable)
        XCTAssertTrue(client.scrollContent(withIdentifier: "table", toOffset: 0, animated: false))
        XCTAssert(app.staticTexts["Label 4"].isHittable)
        XCTAssertTrue(client.scrollContent(withIdentifier: "table", toElementWithIdentifier: "label_50", animated: false))
        XCTAssert(app.staticTexts["Label 50"].isHittable)
    }

    func testScrollContentScrollViewToIdentifier() {
        openTestSection(identifier: "showExtensionScrollView")

        XCTAssertFalse(app.buttons["Button"].isHittable)
        XCTAssertFalse(app.scrollContent(withIdentifier: "scrollView", toElementIndex: 0, animated: false))
        XCTAssertTrue(app.scrollContent(withIdentifier: "scrollView", toElementWithIdentifier: "Button", animated: false))
        XCTAssert(app.buttons["Button"].isHittable)
        XCTAssertTrue(app.scrollContent(withIdentifier: "scrollView", toElementWithIdentifier: "before-content39", animated: false))
        XCTAssert(app.staticTexts["Content 39"].isHittable)
        XCTAssertTrue(app.scrollContent(withIdentifier: "scrollView", toElementWithIdentifier: "pre-content0", animated: false))
        XCTAssert(app.staticTexts["Content 0"].isHittable)
    }

    func testScrollContentCollectionViewVerticalBackwards() {
        openTestSection(identifier: "showExtensionCollectionViewVertical")

        XCTAssertTrue(app.scrollContent(withIdentifier: "collection", toElementWithIdentifier: "button_90", animated: false))
        XCTAssert(app.buttons["Button 90"].isHittable)
        XCTAssertTrue(app.scrollContent(withIdentifier: "collection", toElementWithIdentifier: "button_3", animated: false))
        XCTAssert(app.buttons["Button 3"].isHittable)
        XCTAssertFalse(app.buttons["Button 90"].isHittable)
    }

    func testScrollContentCollectionViewHorizontalBackwards() {
        openTestSection(identifier: "showExtensionCollectionViewHorizontal")

        XCTAssertTrue(app.scrollContent(withIdentifier: "collection", toElementWithIdentifier: "label_90", animated: false))
        XCTAssert(app.staticTexts["90"].isHittable)
        XCTAssertTrue(app.scrollContent(withIdentifier: "collection", toElementWithIdentifier: "label_3", animated: false))
        XCTAssert(app.staticTexts["3"].isHittable)
        XCTAssertFalse(app.staticTexts["90"].isHittable)
    }

    func testScrollContentMissingContainer() {
        openTestSection(identifier: "showExtensionScrollView")

        XCTAssertFalse(app.scrollContent(withIdentifier: "missing-scroll-container", toElementWithIdentifier: "Button", animated: false))
        XCTAssertFalse(app.scrollContent(withIdentifier: "missing-scroll-container", toElementIndex: 0, animated: false))
        XCTAssertFalse(app.scrollContent(withIdentifier: "missing-scroll-container", toOffset: 1, animated: false))
        XCTAssertFalse(app.scrollScrollView(withIdentifierByPage: "missing-scroll-container", animated: false))
    }

    func testScrollContentMissingTarget() {
        openTestSection(identifier: "showExtensionScrollView")

        XCTAssertFalse(app.scrollContent(withIdentifier: "scrollView", toElementWithIdentifier: "missing-scroll-target", animated: false))
    }

    func testScrollContentPagingStopsAtEnd() {
        openTestSection(identifier: "showExtensionScrollView")

        XCTAssertTrue(app.scrollContent(withIdentifier: "scrollView", toOffset: 1, animated: false))
        let last = app.staticTexts["Content 39"]
        XCTAssert(last.isHittable)
        let lastFrame = last.frame
        XCTAssertFalse(app.scrollScrollView(withIdentifierByPage: "scrollView", animated: false))
        XCTAssertEqual(last.frame.minY, lastFrame.minY, accuracy: 1)
        XCTAssert(last.isHittable)
    }

    #if SWIFTUI_APP
        func testScrollContentDoesNotMatchOutsideContainer() {
            openTestSection(identifier: "showExtensionScrollView")

            XCTAssert(app.staticTexts["outside-scroll-target"].isHittable)
            XCTAssertFalse(app.scrollContent(withIdentifier: "scrollView", toElementWithIdentifier: "outside-scroll-target", animated: false))
        }
    #endif

}
