// ScrollContentOversizedTargetTests.swift
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

#if SWIFTUI_APP
class ScrollContentOversizedTargetTests: XCTestCase {
    private var target: XCUIElement {
        app.descendants(matching: .any).matching(identifier: "oversized-target").firstMatch
    }

    private func launchTarget(horizontal: Bool) {
        app.launchArguments.append("--oversized-scroll-target")
        if horizontal {
            app.launchArguments.append("--horizontal-scroll-target")
        }
        app.launchTunnel()
        XCTAssertTrue(app.scrollViews["oversized-scroll"].waitForExistence(timeout: 5))
        if !horizontal {
            XCTAssertFalse(target.exists && target.isHittable)
        }
    }

    func testServerFindsTallTarget() {
        launchTarget(horizontal: false)
        XCTAssertTrue(app.scrollScrollView(withIdentifier: "oversized-scroll", toElementWithIdentifier: "oversized-target", animated: false))
        XCTAssertTrue(target.isHittable)
    }

    func testServerFindsWideTarget() {
        launchTarget(horizontal: true)
        XCTAssertTrue(app.scrollScrollView(withIdentifier: "oversized-scroll", toElementWithIdentifier: "oversized-target", animated: false))
        XCTAssertTrue(target.isHittable)
    }

    func testFallbackFindsTallTarget() throws {
        try checkFallback(horizontal: false)
    }

    func testFallbackFindsWideTarget() throws {
        try checkFallback(horizontal: true)
    }

    private func checkFallback(horizontal: Bool) throws {
        launchTarget(horizontal: horizontal)
        let client = FallbackScrollClient(application: app)
        client.connectedClient = try XCTUnwrap(app.value(forKey: "client") as? SBTUITestTunnelClient)
        XCTAssertTrue(client.scrollContent(withIdentifier: "oversized-scroll", toElementWithIdentifier: "oversized-target", animated: false))
        XCTAssertGreaterThan(client.pageCalls, 0)
        XCTAssertTrue(target.isHittable)
    }
}

// Force the XCTest-only path while retaining real tunnel paging and real
// accessibility frames, so a successful server lookup cannot mask a client bug.
private class FallbackScrollClient: SBTUITestTunnelClient {
    var connectedClient: SBTUITestTunnelClient!
    private(set) var pageCalls = 0

    override func scrollScrollView(withIdentifier identifier: String, toElementWithIdentifier targetIdentifier: String, animated flag: Bool) -> Bool {
        false
    }

    override func scrollScrollView(withIdentifier identifier: String, toOffset targetOffset: CGFloat, animated flag: Bool) -> Bool {
        connectedClient.scrollScrollView(withIdentifier: identifier, toOffset: targetOffset, animated: flag)
    }

    override func scrollScrollView(withIdentifierByPage identifier: String, animated flag: Bool) -> Bool {
        pageCalls += 1
        return connectedClient.scrollScrollView(withIdentifierByPage: identifier, animated: flag)
    }
}
#endif
