// XCTestCase+Extension.swift
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

import XCTest

extension XCTestCase {
    func wait(withTimeout timeout: TimeInterval = 30, assertOnFailure: Bool = true, for predicateBlock: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in predicateBlock() }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)

        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)

        if assertOnFailure {
            XCTAssert(result == .completed)
        }
    }

    /// Opens a test section by scrolling to and tapping on the element with the given identifier.
    /// Works for both UIKit (UITableView) and SwiftUI (List/UICollectionView) by using
    /// the unified scrollContent API and generic descendant queries.
    func openTestSection(identifier: String) {
        let testList = app.descendants(matching: .any).matching(identifier: "example_list").firstMatch
        wait { testList.exists }
      
        let testSection = testList.firstMatch
            .descendants(matching: .any)
            .matching(identifier: identifier)
            .firstMatch
      
        if testSection.exists, testSection.isHittable {
            testSection.tap()
        } else {
            app.scrollContent(withIdentifier: "example_list", toElementWithIdentifier: identifier, animated: true)
            testSection.tap()
        }
    }
}
