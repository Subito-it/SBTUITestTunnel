// DownloadUploadTests.swift
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

class DownloadUploadTests: XCTestCase {
    private let request = NetworkRequests()

    override func setUp() {
        super.setUp()
        app.launchTunnel()
    }

    func testUploadRequest() {
        let uploadData = "This is an upload test".data(using: .utf8)!
        let result = request.uploadTaskNetwork(urlString: "https://httpbin.org/post", data: uploadData)

        XCTAssertEqual(request.returnCode(result), 200)

        let json = request.json(result)
        let data = json["data"] as? String ?? ""
        XCTAssertEqual(data, "This is an upload test")
    }

    func testUploadRequestWithHTTPBody() {
        let uploadData = "This is an upload test".data(using: .utf8)!
        let result = request.uploadTaskNetwork(urlString: "https://httpbin.org/post", data: uploadData)

        XCTAssertEqual(request.returnCode(result), 200)

        let json = request.json(result)
        let data = json["data"] as? String ?? ""
        XCTAssertEqual(data, "This is an upload test")
    }

    func testUploadPUTRequest() {
        let uploadData = "This is a PUT upload test".data(using: .utf8)!
        let result = request.uploadTaskNetwork(urlString: "https://httpbin.org/put", data: uploadData, httpMethod: "PUT")

        XCTAssertEqual(request.returnCode(result), 200)

        let json = request.json(result)
        let data = json["data"] as? String ?? ""
        XCTAssertEqual(data, "This is a PUT upload test")
    }

    func testPostRequestWithLargeBody() {
        let largeBody = String(repeating: "a", count: 20_000)
        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/post", httpMethod: "POST", httpBody: largeBody)

        XCTAssertEqual(request.returnCode(result), 200)

        let json = request.json(result)
        let data = json["data"] as? String ?? ""
        XCTAssertEqual(data.count, 20_000)
        XCTAssertEqual(data, largeBody)
    }

    func testPostRequestWithFormData() {
        let formData = "param1=value1&param2=value2"
        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/post", httpMethod: "POST", httpBody: formData)

        XCTAssertEqual(request.returnCode(result), 200)

        let json = request.json(result)
        let form = json["form"] as? [String: String] ?? [:]
        XCTAssertEqual(form["param1"], "value1")
        XCTAssertEqual(form["param2"], "value2")
    }

    func testDownloadRequest() {
        let result = request.dataTaskNetwork(urlString: "https://httpbin.org/get?download=test")

        XCTAssertEqual(request.returnCode(result), 200)

        let json = request.json(result)
        let args = json["args"] as? [String: String] ?? [:]
        XCTAssertEqual(args["download"], "test")
    }
}
