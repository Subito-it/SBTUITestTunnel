// SwiftUIBackgroundUploadTests.swift
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

#if SWIFTUI_APP
    import SBTUITestTunnelClient
    import XCTest

    final class SwiftUIBackgroundUploadTests: XCTestCase {
        func testBackgroundUploadSendsFileFromAppProcess() throws {
            try assertBackgroundUpload(section: "executeBackgroundUploadDataTaskRequest")
        }

        func testBackgroundUploadWithHTTPBodySendsFileFromAppProcess() throws {
            try assertBackgroundUpload(section: "executeBackgroundUploadDataTaskRequestWithHTTPBody")
        }

        private func assertBackgroundUpload(section: String) throws {
            let server = try LocalHTTPServer(routes: ["/upload": .init(statusCode: 201, body: "file received")])
            app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem]) {
                self.app.userDefaultsSetObject(server.url("/upload") as NSString, forKey: "background_upload_url")
                // A foreground replacement would take this stub instead of
                // reaching the server. Background file uploads bypass it.
                self.app.stubRequests(matching: SBTRequestMatch(url: server.baseURL), response: SBTStubResponse(response: "unexpected foreground stub", returnCode: 299))
            }

            openTestSection(identifier: section)
            let result = app.staticTexts["result"]
            XCTAssertTrue(result.waitForExistence(timeout: 15))
            let data = try XCTUnwrap(Data(base64Encoded: result.label), result.label)
            let response = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            XCTAssertEqual(response["responseCode"] as? Int, 201)
            XCTAssertEqual(server.hits("/upload"), 1)
            XCTAssertEqual(server.bodies("/upload"), [Data("This is a test".utf8)])
        }
    }
#endif
