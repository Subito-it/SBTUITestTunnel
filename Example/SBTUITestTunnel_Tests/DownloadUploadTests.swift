// DownloadUploadTests.swift
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

import Foundation
import SBTUITestTunnelClient
import XCTest

class DownloadUploadTests: XCTestCase {
    override func setUp() {
        super.setUp()

        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem])

        expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.tables)
        waitForExpectations(timeout: 15.0, handler: nil)

        Thread.sleep(forTimeInterval: 1.0)
    }

    func testSingleDownload() {
        let randomString = ProcessInfo.processInfo.globallyUniqueString

        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let testFilePath = paths.first!.appending("/test_file_a.txt")

        if FileManager.default.fileExists(atPath: testFilePath) {
            try! FileManager.default.removeItem(atPath: testFilePath)
        }

        try! (randomString.data(using: .utf8))?.write(to: URL(fileURLWithPath: testFilePath))

        app.uploadItem(atPath: testFilePath, toPath: "test_file_b.txt", relativeTo: .documentDirectory)

        let uploadData = app.downloadItems(fromPath: "test_file_b.txt", relativeTo: .documentDirectory)?.first!

        let uploadedString = String(data: uploadData!, encoding: .utf8)

        XCTAssertTrue(randomString == uploadedString)
    }

    func testMultipleDownload() {
        let randomString = ProcessInfo.processInfo.globallyUniqueString

        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let testFilePath = paths.first!.appending("/test_file_a.txt")

        if FileManager.default.fileExists(atPath: testFilePath) {
            try! FileManager.default.removeItem(atPath: testFilePath)
        }

        try! (randomString.data(using: .utf8))?.write(to: URL(fileURLWithPath: testFilePath))

        app.uploadItem(atPath: testFilePath, toPath: "test_file_1.txt", relativeTo: .documentDirectory)
        app.uploadItem(atPath: testFilePath, toPath: "test_file_2.txt", relativeTo: .documentDirectory)
        app.uploadItem(atPath: testFilePath, toPath: "test_file_3.txt", relativeTo: .documentDirectory)

        if let uploadDatas = app.downloadItems(fromPath: "test_file_*.txt", relativeTo: .documentDirectory) {
            XCTAssertEqual(uploadDatas.count, 3)

            for uploadData in uploadDatas {
                let uploadedString = String(data: uploadData, encoding: .utf8)

                XCTAssertTrue(randomString == uploadedString)
            }
        } else {
            XCTFail("No upload data received")
        }
    }

    func testMonitorPostRequestWithHTTPLargeBodyInAppProcess() {
        let largeBody = String(repeating: "a", count: 20000)
        let matchingRequest = SBTRequestMatch(url: "postman-echo.com", method: "POST")
        app.monitorRequests(matching: matchingRequest)

        XCTAssertTrue(app.tables.firstMatch.staticTexts["executePostDataTaskRequestWithLargeHTTPBody"].waitForExistence(timeout: 5))
        app.tables.firstMatch.staticTexts["executePostDataTaskRequestWithLargeHTTPBody"].tap()

        XCTAssertTrue(app.waitForMonitoredRequests(matching: matchingRequest, timeout: 10))
        let requests = app.monitoredRequestsFlushAll()
        XCTAssertEqual(requests.count, 1)

        for request in requests {
            guard let httpBody = request.request?.httpBody else {
                XCTFail("Missing http body")
                continue
            }

            XCTAssertEqual(String(data: httpBody, encoding: .utf8), largeBody)

            XCTAssert((request.responseString()!).contains("postman-echo.com"))
            XCTAssert(request.timestamp > 0.0)
            XCTAssert(request.requestTime > 0.0)
        }

        XCTAssert(app.stubRequestsRemoveAll())
        XCTAssert(app.monitorRequestRemoveAll())
    }
}
