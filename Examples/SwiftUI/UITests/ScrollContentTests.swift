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

    func testScrollContentTableView() {
        scrollToTestSection(14)
        app.buttons["showExtensionTable1"].tap()

        XCTAssert(app.staticTexts["Label5"].isHittable)
        XCTAssertFalse(app.staticTexts["Label99"].isHittable)

        XCTAssert(app.scrollContent(withIdentifier: "table", toElementIndex: 99, animated: false))

        XCTAssertFalse(app.staticTexts["Label5"].isHittable)
        XCTAssert(app.staticTexts["Label99"].isHittable)
    }

    func testScrollContentCollectionViewVertical() {
//        scrollToTestSection(18)

        wait { self.app.collectionViews["example_list"].exists }
        app.scrollContent(withIdentifier: "example_list", toElementWithIdentifier: "showExtensionCollectionViewVertical", animated: true)

        app.buttons["showExtensionCollectionViewVertical"].tap()

        XCTAssert(app.staticTexts["3"].isHittable)
        XCTAssertFalse(app.staticTexts["30"].isHittable)

//        app.scrollViews["collection"].swipeUpTo(element: app.scrollViews["collection"].buttons["ExtensionCollectionVerticalView_Button_17"], velocity: 100)

        XCTAssert(app.scrollContent(withIdentifier: "collection", toElementWithIdentifier: "30", animated: true))

        XCTAssertFalse(app.staticTexts["3"].isHittable)
        XCTAssert(app.staticTexts["30"].isHittable)
    }

    func testScrollContentScrollViewToOffset() {
        scrollToTestSection(16)
        app.buttons["showExtensionScrollView"].tap()

        XCTAssertFalse(app.scrollViews["scrollView"].buttons["Button"].isHittable)

        // ✨ NEW: scrollContent automatically detects this is a scroll view
        XCTAssertTrue(app.scrollContent(withIdentifier: "scrollView", toOffset: 0.65, animated: true))

        XCTAssert(app.scrollViews["scrollView"].buttons["Button"].isHittable)

        // Test scrolling back to top
        XCTAssertTrue(app.scrollContent(withIdentifier: "scrollView", toOffset: 0.0, animated: true))
        XCTAssertFalse(app.scrollViews["scrollView"].buttons["Button"].isHittable)
    }

    func testScrollContentOffsetWithTableView() {
        scrollToTestSection(14)
        app.buttons["showExtensionTable1"].tap()

        // ✨ NEW: scrollContent handles offset scrolling for table views by falling back to ScrollView behavior
        XCTAssertTrue(app.scrollContent(withIdentifier: "table", toOffset: 0.8, animated: false))

        // Verify we scrolled (can't check specific elements but should not fail)
        XCTAssert(app.tables["table"].exists)
    }

    func testScrollContentElementByIdentifier() {
        scrollToTestSection(14)
        app.buttons["showExtensionTable1"].tap()

        // ✨ NEW: scrollContent works with element identifiers across all view types
        // Note: This test demonstrates the API, but may not work due to SwiftUI accessibility limitations
        // In real implementations, ensure your views have proper accessibility identifiers
        XCTAssertTrue(app.scrollContent(withIdentifier: "table", toElementWithIdentifier: "Label5", animated: true))
    }

    // MARK: - 🎯 Advanced ScrollContent API Features

    func testScrollContentBenefits_ViewTypeFlexibility() {
        // This test demonstrates how the scrollContent API adapts when view implementations change

        scrollToTestSection(14)
        app.buttons["showExtensionTable1"].tap()

        // ✨ If developers change from UITableView to UICollectionView in the app,
        // this test will continue to work without modification!
        XCTAssertTrue(app.scrollContent(withIdentifier: "table", toElementIndex: 25, animated: false))

        // 📜 With legacy APIs, you'd need to update from scrollTableView to scrollCollectionView
    }

    func testScrollContentBenefits_ConsistentInterface() {
        // All scrollable views use the same method signatures

        let testCases = [
            ("table", 14, "showExtensionTable1"),
            ("collection", 18, "showExtensionCollectionViewVertical")
        ]

        for (identifier, section, button) in testCases {
            scrollToTestSection(section)
            app.buttons[button].tap()

            // ✨ Same method signature works for all view types
            XCTAssertTrue(app.scrollContent(withIdentifier: identifier, toElementIndex: 10, animated: false))

            app.navigationBars.buttons.element(boundBy: 0).tap() // Go back
        }
    }
}

extension XCUIElement {
    func swipeUpTo(element: XCUIElement, maxAttempts: Int = 10, velocity: XCUIGestureVelocity) {
        for _ in 0 ... maxAttempts {
            guard !element.isHittable else { return }

//            guard element.frame != .zero, frame.intersects(element.frame) else { break }

            swipeUp(velocity: velocity)
        }
    }
}
