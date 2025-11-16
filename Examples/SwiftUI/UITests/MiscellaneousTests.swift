// MiscellaneousTests.swift
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

class MiscellaneousTests: XCTestCase {
    func testLaunchTimeWithStubs() throws {
        func stubAndGetDuration(amount: Int) -> CFAbsoluteTime {
            let start = CFAbsoluteTimeGetCurrent()
            for _ in 1 ... amount {
                app.stubRequests(
                    matching: SBTRequestMatch(url: "something", method: "GET"),
                    response: SBTStubResponse(response: Data(), returnCode: 200)
                )
            }
            return CFAbsoluteTimeGetCurrent() - start
        }

        var durations: [CFAbsoluteTime] = []
        app.launchTunnel {
            durations.append(stubAndGetDuration(amount: 10))
            durations.append(stubAndGetDuration(amount: 10))
            durations.append(stubAndGetDuration(amount: 10))
            durations.append(stubAndGetDuration(amount: 10))
        }

        // All metrics should be of similar value, so compare them with the first one.
        // Multiply the first one by two to give some room for variation
        let referenceMetric = try XCTUnwrap(durations.first) * 2
        XCTAssertTrue(
            durations.allSatisfy { $0 < referenceMetric },
            "Stubbing took longer than expected: metrics \(durations) are higher than the reference \(referenceMetric)"
        )
    }

    func testStartupCommands() {
        let userDefaultsKey = "test_ud_key"
        let randomString = ProcessInfo.processInfo.globallyUniqueString

        app.launchTunnel {
            self.app.userDefaultsSetObject(randomString as NSCoding & NSObjectProtocol, forKey: userDefaultsKey)
            self.app.setUserInterfaceAnimationsEnabled(false)
        }

        XCTAssertEqual(randomString, app.userDefaultsObject(forKey: userDefaultsKey) as! String)
    }

    func testStartupCommandsWaitsAppropriately() {
        let userDefaultsKey = "test_ud_key"
        let randomString = ProcessInfo.processInfo.globallyUniqueString

        var startupBlockProcessed = false

        app.launchTunnel {
            self.app.userDefaultsSetObject(randomString as NSCoding & NSObjectProtocol, forKey: userDefaultsKey)
            self.app.setUserInterfaceAnimationsEnabled(false)
            Thread.sleep(forTimeInterval: 8.0)
            startupBlockProcessed = true
        }

        XCTAssert(startupBlockProcessed)
    }

    func testCustomCommand() {
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem])

        let randomString = ProcessInfo.processInfo.globallyUniqueString
        let retObj = app.performCustomCommandNamed("myCustomCommandReturnNil", object: NSString(string: randomString))
        let randomStringRemote = app.userDefaultsObject(forKey: "custom_command_test") as! String
        XCTAssertEqual(randomString, randomStringRemote)
        XCTAssertNil(retObj)

        let randomString2 = ProcessInfo.processInfo.globallyUniqueString
        let retObj2 = app.performCustomCommandNamed("myCustomCommandReturn123", object: NSString(string: randomString2))
        let randomStringRemote2 = app.userDefaultsObject(forKey: "custom_command_test") as! String
        XCTAssertEqual(randomString2, randomStringRemote2)
        XCTAssertEqual("123", retObj2 as! String)

        XCUIDevice.shared.press(XCUIDevice.Button.home)
        sleep(5)
        app.activate()

        let retObj3 = app.performCustomCommandNamed("myCustomCommandReturn123", object: nil)
        XCTAssertNil(app.userDefaultsObject(forKey: "custom_command_test"))
        XCTAssertEqual("123", retObj3 as! String)
    }

    func testStubWithFilename() {
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem])

        let requestMatch = SBTRequestMatch(url: "postman-echo.com")
        let response = SBTStubResponse(fileNamed: "test_file.json")
        app.monitorRequests(matching: requestMatch)
        app.stubRequests(matching: requestMatch, response: response)

        app.cells["executeDataTaskRequest"].tap()

        let textResult = app.staticTexts["result"]
        wait { textResult.exists }
        let result = textResult.label
        let resultData = Data(base64Encoded: result)!
        let resultDict = try! JSONSerialization.jsonObject(with: resultData, options: []) as! [String: Any]

        let networkBase64 = resultDict["data"] as! String
        let networkString = String(data: Data(base64Encoded: networkBase64)!, encoding: .utf8)

        let monitoredRequests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(monitoredRequests.count, 1)
        let responseHeaders = monitoredRequests.first?.response?.allHeaderFields

        XCTAssertEqual(networkString, "{\"hello\":\"there\"}\n")
        XCTAssertEqual(responseHeaders?["Content-Type"] as? String, "application/json")
    }

    func testShutdown() {
        app.launchTunnel()

        app.terminate()
        XCTAssert(app.wait(for: .notRunning, timeout: 5))

        app.launchTunnel()
        XCTAssert(app.wait(for: .runningForeground, timeout: 5))

        expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.tables)
        waitForExpectations(timeout: 15.0, handler: nil)
    }

    func testLaunchArgumentsResetBetweenLaunches() {
        let userDefaultKey = "test_key"
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem])
        XCTAssertNil(app.userDefaultsObject(forKey: userDefaultKey))

        let randomString = ProcessInfo.processInfo.globallyUniqueString
        app.userDefaultsSetObject(randomString as NSCoding & NSObjectProtocol, forKey: userDefaultKey)

        app.terminate()

        Thread.sleep(forTimeInterval: 3.0)

        app.launchTunnel()
        // UserDefaults shouldn't get reset
        XCTAssertEqual(randomString, app.userDefaultsObject(forKey: userDefaultKey) as? String)
    }

    func testTableViewScrolling() {
        app.launchTunnel()

        app.cells["showExtensionTable1"].tap()

        XCTAssertFalse(app.staticTexts["Label5"].isHittable)

        XCTAssertTrue(app.scrollTableView(withIdentifier: "table", toRowIndex: 100, animated: false))

        XCTAssert(app.staticTexts["Label5"].isHittable)
    }

    func testTableViewScrolling2() {
        app.launchTunnel()

        app.cells["showExtensionTable2"].tap()

        XCTAssertFalse(app.staticTexts["80"].isHittable)

        XCTAssertTrue(app.scrollTableView(withIdentifier: "table", toElementWithIdentifier: "80", animated: true))

        XCTAssert(app.staticTexts["80"].isHittable)
    }

    func testCollectionViewScrollingVertical() {
        app.launchTunnel()

        app.cells["showExtensionCollectionViewVertical"].tap()

        XCTAssertFalse(app.staticTexts["30"].isHittable)

        XCTAssertTrue(app.scrollCollectionView(withIdentifier: "collection", toElementIndex: 30, animated: true))
        XCTAssert(app.staticTexts["30"].isHittable)

        XCTAssertFalse(app.staticTexts["50"].isHittable)

        XCTAssertTrue(app.scrollCollectionView(withIdentifier: "collection", toElementWithIdentifier: "50", animated: true))
        XCTAssert(app.staticTexts["50"].isHittable)
    }

    func testCollectionViewScrollingHorizontal() {
        app.launchTunnel()

        app.cells["showExtensionCollectionViewHorizontal"].tap()

        XCTAssertFalse(app.staticTexts["10"].isHittable)

        XCTAssertTrue(app.scrollCollectionView(withIdentifier: "collection", toElementIndex: 10, animated: true))
        XCTAssert(app.staticTexts["10"].isHittable)

        XCTAssertFalse(app.staticTexts["40"].isHittable)

        XCTAssertTrue(app.scrollCollectionView(withIdentifier: "collection", toElementWithIdentifier: "40", animated: true))
        XCTAssert(app.staticTexts["40"].isHittable)
    }

    func testScrollViewScrollToElement() {
        app.launchTunnel()

        app.cells["showExtensionScrollView"].tap()

        XCTAssertFalse(app.buttons["Button"].isHittable)

        XCTAssertTrue(app.scrollScrollView(withIdentifier: "scrollView", toElementWithIdentifier: "Button", animated: true))

        XCTAssert(app.buttons["Button"].isHittable)
    }

    func testScrollViewScrollToOffset() {
        app.launchTunnel()

        app.cells["showExtensionScrollView"].tap()

        XCTAssertFalse(app.scrollViews["scrollView"].buttons["Button"].isHittable)

        XCTAssertTrue(app.scrollScrollView(withIdentifier: "scrollView", toOffset: 0.65, animated: true))

        XCTAssert(app.scrollViews["scrollView"].buttons["Button"].isHittable)

        XCTAssertTrue(app.scrollScrollView(withIdentifier: "scrollView", toOffset: 0.0, animated: true))

        XCTAssertFalse(app.scrollViews["scrollView"].buttons["Button"].isHittable)
    }

    func testUrlProtocolIsRegisteredWhenRunningUITests() {
        app.launchTunnel()

        guard let isRegistered = app.performCustomCommandNamed("isSBTProxyURLProtocolRegistered", object: nil) as? NSNumber else {
            return XCTFail("Unexpected object returned")
        }

        XCTAssert(isRegistered.boolValue)
    }

    // FIXME: SBTProxyURLProtocol is not available in Swift Package Manager build
    // func testUrlProtocolIsNotRegisteredWhenDebuggingApplication() {
    //     XCTAssertFalse(SBTUITestTunnelServer.takeOff())
    //
    //     SBTProxyURLProtocol.stubRequests(matching: SBTRequestMatch(url: ".*"), stubResponse: SBTStubResponse(response: ""))
    //
    //     let request = URLRequest(url: URL(string: "https://www.subito.it")!)
    //     let selector = NSSelectorFromString("_protocolClassForRequest:")
    //     guard let klass = URLProtocol.perform(selector, with: request)?.takeUnretainedValue() as? AnyClass else {
    //         return XCTFail("Unexpected object returned")
    //     }
    //
    //     XCTAssertEqual(NSStringFromClass(klass), "_NSURLHTTPProtocol")
    // }

    func testUserDefaultDefaultsRegistration() {
        app.launchTunnel()

        app.userDefaultsRegisterDefaults(["key": "value"])
        XCTAssertEqual(app.userDefaultsObject(forKey: "key") as? String, "value")

        app.terminate()
        app.launchTunnel()

        XCTAssertNil(app.userDefaultsObject(forKey: "key"))
    }

    func testLaunchTimeWithUserDefaults() throws {
        func writeToDefaultsAndGetDuration(amount: Int) -> CFAbsoluteTime {
            let randomString = ProcessInfo.processInfo.globallyUniqueString
            let start: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
            for i in 1 ... amount {
                app.userDefaultsSetObject(randomString as NSCoding & NSObjectProtocol, forKey: "\(i)")
            }
            return CFAbsoluteTimeGetCurrent() - start
        }

        var durations: [CFAbsoluteTime] = []
        app.launchTunnel {
            for _ in 1 ... 10 {
                durations.append(writeToDefaultsAndGetDuration(amount: 50))
            }
        }

        let last5avg = durations.suffix(5).reduce(0, +) / 5

        for duration in durations.dropFirst() {
            XCTAssertTrue(duration < last5avg * 2.5, "Last 5 average: \(last5avg), duration: \(duration). All durations \(durations)")
        }
    }

    func testCrashingAppDoesNotCrashUITest() throws {
        throw XCTSkip("This test should only be run manually")

        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem])

        XCTAssert(app.monitorRequestRemoveAll())
        app.cells["crashApp"].tap()

        Thread.sleep(forTimeInterval: 2.0)

        XCTAssertFalse(app.monitorRequestRemoveAll())
        XCTAssertFalse(app.cells["crashApp"].exists)
        XCTAssertFalse(app.wait(for: .runningForeground, timeout: 0.1))
    }
}
