// (c) Subito.it proprietary and confidential

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

    func scrollToTestSection(_ index: Int) {
        wait { self.app.collectionViews["example_list"].exists }
        app.scrollCollectionView(withIdentifier: "example_list", toElementIndex: index, animated: true)
    }
}
