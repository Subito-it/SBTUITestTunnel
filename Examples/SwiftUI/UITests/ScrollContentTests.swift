// (c) Subito.it proprietary and confidential

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

        XCTAssert(app.staticTexts["Label 5"].isHittable)
        XCTAssertFalse(app.staticTexts["Label 99"].isHittable)

        XCTAssert(app.scrollContent(withIdentifier: "table", toElementIndex: 99, animated: false))

        XCTAssertFalse(app.staticTexts["Label 5"].isHittable)
        XCTAssert(app.staticTexts["Label 99"].isHittable)
    }

    func testScrollContentTableViewToOffset() {
        openTestSection(identifier: "showExtensionTable1")

        XCTAssert(app.staticTexts["Label 4"].isHittable)
        XCTAssertFalse(app.staticTexts["Label 40"].isHittable)

        XCTAssertTrue(app.scrollContent(withIdentifier: "table", toOffset: 0.5, animated: false))

        XCTAssertFalse(app.staticTexts["Label 4"].isHittable)
        XCTAssert(app.staticTexts["Label 40"].isHittable)

        XCTAssertTrue(app.scrollContent(withIdentifier: "table", toOffset: 0, animated: false))

        XCTAssert(app.staticTexts["Label 4"].isHittable)
        XCTAssertFalse(app.staticTexts["Label 40"].isHittable)
    }

    func testScrollContentTableViewToIdentifier() {
        openTestSection(identifier: "showExtensionTable1")

        XCTAssert(app.staticTexts["Label 5"].isHittable)
        XCTAssertFalse(app.staticTexts["Label 99"].isHittable)

        XCTAssert(app.scrollContent(withIdentifier: "table", toElementWithIdentifier: "label_99", animated: false))

        XCTAssertFalse(app.staticTexts["Label 5"].isHittable)
        XCTAssert(app.staticTexts["Label 99"].isHittable)

        XCTAssert(app.scrollContent(withIdentifier: "table", toElementWithIdentifier: "label_50", animated: false))

        XCTAssertFalse(app.staticTexts["Label 5"].isHittable)
        XCTAssertFalse(app.staticTexts["Label 99"].isHittable)
        XCTAssert(app.staticTexts["Label 50"].isHittable)
    }

    func testScrollContentCollectionViewVertical() {
        openTestSection(identifier: "showExtensionCollectionViewVertical")

        XCTAssert(app.buttons["Button 3"].isHittable)
        XCTAssertFalse(app.buttons["Button 30"].isHittable)

        XCTAssert(app.scrollContent(withIdentifier: "collection", toElementWithIdentifier: "button_30", animated: true))

        XCTAssertFalse(app.buttons["Button 3"].isHittable)
        XCTAssert(app.buttons["Button 30"].isHittable)
    }

    func testScrollContentCollectionViewHorizontal() {
        openTestSection(identifier: "showExtensionCollectionViewHorizontal")

        XCTAssert(app.staticTexts["3"].isHittable)
        XCTAssertFalse(app.staticTexts["30"].isHittable)

        XCTAssert(app.scrollContent(withIdentifier: "collection", toElementWithIdentifier: "label_30", animated: true))

        XCTAssertFalse(app.staticTexts["3"].isHittable)
        XCTAssert(app.staticTexts["30"].isHittable)
    }

    func testScrollContentScrollViewToOffset() {
        openTestSection(identifier: "showExtensionScrollView")

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
}
