//
//  XCTestCase+Extension.swift
//  SBTUITestTunnel_SwiftUI_Tests
//
//  Created by SBTUITestTunnel on 15/11/2024.
//  Copyright © 2024 Tomas Camin. All rights reserved.
//

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
}
