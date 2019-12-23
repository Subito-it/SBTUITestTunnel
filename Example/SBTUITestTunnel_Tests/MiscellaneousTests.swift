// MiscellaneousTests.swift
//
// Copyright (C) 2016 Subito.it S.r.l (www.subito.it)
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
import Foundation
import XCTest

class MiscellaneousTests: XCTestCase {
    
    func testStartupCommands() {
        let userDefaultsKey = "test_ud_key"
        let randomString = ProcessInfo.processInfo.globallyUniqueString
        
        app.launchTunnel() {
            self.app.userDefaultsSetObject(randomString as NSCoding & NSObjectProtocol, forKey: userDefaultsKey)
            self.app.setUserInterfaceAnimationsEnabled(false)
        }
        
        XCTAssertEqual(randomString, app.userDefaultsObject(forKey: userDefaultsKey) as! String)
    }

    func testStartupCommandsWaitsAppropriately() {
        let userDefaultsKey = "test_ud_key"
        let randomString = ProcessInfo.processInfo.globallyUniqueString

        var startupBlockProcessed = false

        app.launchTunnel() {
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
    
    func testTakeOffWait() {
        app.launchArguments = ["wait_for_startup_test"]
        
        var start = Date.distantFuture;
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem]) {
            start = Date()
        }
        
        let delta = start.timeIntervalSinceNow
        XCTAssert(delta < -5.0)
    }
    
    func testStubWithFilename() {
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem])
        
        let requestMatch = SBTRequestMatch(url: "httpbin.org")
        let response = SBTStubResponse(fileNamed: "test_file.json")
        app.monitorRequests(matching: requestMatch)
        app.stubRequests(matching: requestMatch, response: response)
        
        app.cells["executeDataTaskRequest"].tap()
        
        expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: app.textViews["result"], handler: nil)
        waitForExpectations(timeout: 10.0, handler: nil)
        
        let result = app.textViews["result"].value as! String
        let resultData = Data(base64Encoded: result)!
        let resultDict = try! JSONSerialization.jsonObject(with: resultData, options: []) as! [String: Any]
        
        let networkBase64 = resultDict["data"] as! String
        let networkString = String(data: Data(base64Encoded: networkBase64)!, encoding: .utf8)
        
        let monitoredRequests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(monitoredRequests.count, 1)
        let responsetHeaders = monitoredRequests.first?.response?.allHeaderFields
        
        XCTAssertEqual(networkString, "{\"hello\":\"there\"}\n")
        XCTAssertEqual(responsetHeaders!["Content-Type"] as? String, "application/json")
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
        
        Thread.sleep(forTimeInterval: 3.0)
        
        app.terminate()
        
        app.launchTunnel()
        // UserDefaults shouldn't get reset
        XCTAssertEqual(randomString, app.userDefaultsObject(forKey: userDefaultKey) as? String)
    }
    
    func testTableViewScrolling() {
        app.launchTunnel()
        
        app.cells["showExtensionTable1"].tap()
        
        XCTAssertFalse(app.staticTexts["Label5"].isHittable)
        
        app.scrollTableView(withIdentifier: "table", toRow: 100, animated: false)

        expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: app.staticTexts["Label5"])
        waitForExpectations(timeout: 15.0, handler: nil)
    }
    
    func testScrollViewScrolling() {
        app.launchTunnel()
        
        app.cells["showExtensionScrollView"].tap()
        
        XCTAssertFalse(app.buttons["Button"].isHittable)
        
        app.scrollScrollView(withIdentifier: "scrollView", toElementWitIdentifier: "Button", animated: true)
        
        expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: app.buttons["Button"])
        waitForExpectations(timeout: 15.0, handler: nil)
        
        XCTAssert(app.buttons["Button"].isHittable)
    }
}
