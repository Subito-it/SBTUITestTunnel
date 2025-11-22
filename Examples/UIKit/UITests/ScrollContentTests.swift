// ScrollContentTests.swift
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
import SBTUITestTunnelServer
import XCTest

/**
 * ScrollContentTests demonstrates both the new scrollContent API and the legacy specific APIs.
 *
 * This test class showcases:
 * - 🆕 scrollContent API that automatically detects view types
 * - 📜 Legacy specific APIs for comparison
 * - 🔄 Migration examples showing equivalent functionality
 */
class ScrollContentTests: XCTestCase {

    override func setUp() {
        super.setUp()
        app.launchTunnel()
    }

    // MARK: - 🆕 scrollContent API Tests

    func testScrollContentTableView() {
        scrollToTestSection("showExtensionTable1")

        XCTAssertFalse(app.staticTexts["Label5"].isHittable)

        // ✨ scrollContent automatically detects this is a table view
        XCTAssertTrue(app.scrollContent(withIdentifier: "table", toElementIndex: 100, animated: false))

        XCTAssert(app.staticTexts["Label5"].isHittable)
    }

    func testScrollContentCollectionViewVertical() {
        scrollToTestSection("showExtensionCollectionViewVertical")

        XCTAssertFalse(app.staticTexts["30"].isHittable)

        // ✨ scrollContent automatically detects this is a collection view
        XCTAssertTrue(app.scrollContent(withIdentifier: "collection", toElementIndex: 30, animated: true))
        XCTAssert(app.staticTexts["30"].isHittable)
    }

    func testScrollContentScrollViewToOffset() {
        scrollToTestSection("showExtensionScrollView")

        XCTAssertFalse(app.scrollViews["scrollView"].buttons["Button"].isHittable)

        // ✨ scrollContent automatically detects this is a scroll view
        XCTAssertTrue(app.scrollContent(withIdentifier: "scrollView", toOffset: 0.65, animated: true))

        XCTAssert(app.scrollViews["scrollView"].buttons["Button"].isHittable)

        // Test scrolling back to top
        XCTAssertTrue(app.scrollContent(withIdentifier: "scrollView", toOffset: 0.0, animated: true))
        XCTAssertFalse(app.scrollViews["scrollView"].buttons["Button"].isHittable)
    }

    func testScrollContentOffsetWithTableView() {
        scrollToTestSection("showExtensionTable1")

        // ✨ scrollContent handles offset scrolling for table views by falling back to ScrollView behavior
        XCTAssertTrue(app.scrollContent(withIdentifier: "table", toOffset: 0.8, animated: false))

        // Verify we scrolled (can't check specific elements but should not fail)
        XCTAssert(app.tables["table"].exists)
    }

    func testScrollContentElementByIdentifier() {
        scrollToTestSection("showExtensionTable1")

        // ✨ scrollContent works with element identifiers across all view types
        // This demonstrates the API capability for element-based scrolling
        XCTAssertTrue(app.scrollContent(withIdentifier: "table", toElementWithIdentifier: "Label5", animated: true))
    }

    // MARK: - 📜 Legacy API Comparison Tests

    func testLegacyTableViewScrolling() {
        scrollToTestSection("showExtensionTable1")

        XCTAssertFalse(app.staticTexts["Label5"].isHittable)

        // 📜 OLD: Specific table view API - requires knowing the view type
        XCTAssertTrue(app.scrollTableView(withIdentifier: "table", toRowIndex: 100, animated: false))

        XCTAssert(app.staticTexts["Label5"].isHittable)
    }

    func testLegacyCollectionViewScrolling() {
        scrollToTestSection("showExtensionCollectionViewVertical")

        XCTAssertFalse(app.staticTexts["30"].isHittable)

        // 📜 OLD: Specific collection view API - requires knowing the view type
        XCTAssertTrue(app.scrollCollectionView(withIdentifier: "collection", toElementIndex: 30, animated: true))
        XCTAssert(app.staticTexts["30"].isHittable)
    }

    func testLegacyScrollViewScrolling() {
        scrollToTestSection("showExtensionScrollView")

        XCTAssertFalse(app.scrollViews["scrollView"].buttons["Button"].isHittable)

        // 📜 OLD: Specific scroll view API - requires knowing the view type
        XCTAssertTrue(app.scrollScrollView(withIdentifier: "scrollView", toOffset: 0.65, animated: true))

        XCTAssert(app.scrollViews["scrollView"].buttons["Button"].isHittable)
    }

    // MARK: - 🔄 Migration Examples: Old vs New

    func testMigrationExample_TableViewScrolling() {
        scrollToTestSection("showExtensionTable1")

        // 📜 OLD WAY: Specific API, need to know it's a table view
        // XCTAssertTrue(app.scrollTableView(withIdentifier: "table", toRowIndex: 50, animated: true))

        // ✨ NEW WAY: scrollContent API, automatic detection
        XCTAssertTrue(app.scrollContent(withIdentifier: "table", toElementIndex: 50, animated: true))

        // Same result, simpler API! 🎉
    }

    func testMigrationExample_CollectionViewScrolling() {
        scrollToTestSection("showExtensionCollectionViewHorizontal")

        // 📜 OLD WAY: Specific API, need to know it's a collection view
        // XCTAssertTrue(app.scrollCollectionView(withIdentifier: "collection", toElementIndex: 15, animated: true))

        // ✨ NEW WAY: scrollContent API, automatic detection
        XCTAssertTrue(app.scrollContent(withIdentifier: "collection", toElementIndex: 15, animated: true))

        // Same result, more flexible! 🎉
    }

    func testMigrationExample_ScrollViewScrolling() {
        scrollToTestSection("showExtensionScrollView")

        // 📜 OLD WAY: Specific API, need to know it's a scroll view
        // XCTAssertTrue(app.scrollScrollView(withIdentifier: "scrollView", toOffset: 0.5, animated: true))

        // ✨ NEW WAY: scrollContent API, automatic detection
        XCTAssertTrue(app.scrollContent(withIdentifier: "scrollView", toOffset: 0.5, animated: true))

        // Same result, consistent interface! 🎉
    }

    // MARK: - 🎯 Advanced scrollContent Features

    func testScrollContentBenefits_ViewTypeFlexibility() {
        // This test demonstrates how the scrollContent API adapts when view implementations change

        scrollToTestSection("showExtensionTable1")

        // ✨ If developers change from UITableView to UICollectionView in the app,
        // this test will continue to work without modification!
        XCTAssertTrue(app.scrollContent(withIdentifier: "table", toElementIndex: 25, animated: false))

        // 📜 With legacy APIs, you'd need to update from scrollTableView to scrollCollectionView
    }

    func testScrollContentBenefits_ConsistentInterface() {
        // All scrollable views use the same method signatures

        let testCases = [
            ("table", "showExtensionTable1"),
            ("collection", "showExtensionCollectionViewVertical")
        ]

        for (identifier, cellIdentifier) in testCases {
            scrollToTestSection(cellIdentifier)

            // ✨ Same method signature works for all view types
            XCTAssertTrue(app.scrollContent(withIdentifier: identifier, toElementIndex: 10, animated: false))

            app.navigationBars.buttons.firstMatch.tap() // Go back
        }
    }

    func testScrollContentBenefits_OffsetFallback() {
        // Demonstrates how the scrollContent API gracefully handles offset scrolling for table/collection views

        scrollToTestSection("showExtensionTable1")

        // ✨ scrollContent automatically falls back to ScrollView behavior for offset scrolling
        // This works even though UITableView doesn't natively support normalized offsets
        XCTAssertTrue(app.scrollContent(withIdentifier: "table", toOffset: 0.3, animated: true))
        XCTAssertTrue(app.scrollContent(withIdentifier: "table", toOffset: 0.7, animated: true))
        XCTAssertTrue(app.scrollContent(withIdentifier: "table", toOffset: 0.0, animated: true))

        // 📜 OLD: Would require separate logic to handle offset scrolling for table views
    }

    func testScrollContentBenefits_ErrorHandling() {
        // Test scrollContent API error handling with invalid identifiers

        // ✨ scrollContent provides consistent error handling across all view types
        XCTAssertFalse(app.scrollContent(withIdentifier: "nonexistent", toElementIndex: 10, animated: false))
        XCTAssertFalse(app.scrollContent(withIdentifier: "nonexistent", toOffset: 0.5, animated: false))

        // The API fails gracefully without needing to know what type of view it's looking for
    }
}