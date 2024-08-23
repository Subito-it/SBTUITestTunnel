
import Foundation
import SBTUITestTunnelClient
import XCTest

final class BuildTest: XCTestCase {
    func testTargetBuild() {
        let request = SBTRequestMatch(url: "https://www.subito.it")
        XCTAssertNotNil(request)
    }
}
