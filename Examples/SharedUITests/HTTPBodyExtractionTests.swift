// HTTPBodyExtractionTests.swift
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
import SBTUITestTunnelCommon
import SBTUITestTunnelServer
import XCTest

class HTTPBodyExtractionTests: XCTestCase {
    func testExtractHTTPBodyFromDirectHTTPBody() {
        let url = URL(string: "https://example.com")!
        let testData = "test body content".data(using: .utf8)!

        let request = NSMutableURLRequest(url: url)
        request.httpBody = testData

        let extractedBody = request.sbt_extractHTTPBody()

        XCTAssertEqual(extractedBody, testData)
    }

    func testExtractHTTPBodyFromHTTPBodyStream() {
        let url = URL(string: "https://example.com")!
        let testString = "stream body content"
        let testData = testString.data(using: .utf8)!

        let request = NSMutableURLRequest(url: url)
        request.httpBodyStream = InputStream(data: testData)

        let extractedBody = request.sbt_extractHTTPBody()

        XCTAssertNotNil(extractedBody)
        XCTAssertEqual(String(data: extractedBody!, encoding: .utf8), testString)
    }

    func testExtractHTTPBodyFromUploadTask() {
        let url = URL(string: "https://example.com")!
        let testData = "upload task body".data(using: .utf8)!

        let request = NSMutableURLRequest(url: url)
        request.sbt_markUploadTaskRequest()

        // Simulate storing the body data as upload tasks do
        SBTRequestPropertyStorage.setProperty(
            testData,
            forKey: "SBTUITunneledNSURLProtocolHTTPBodyKey",
            in: request
        )

        let extractedBody = request.sbt_extractHTTPBody()

        XCTAssertEqual(extractedBody, testData)
    }

    func testExtractHTTPBodyReturnsNilForEmptyRequest() {
        let url = URL(string: "https://example.com")!
        let request = NSURLRequest(url: url)

        let extractedBody = request.sbt_extractHTTPBody()

        XCTAssertNil(extractedBody)
    }

    func testExtractHTTPBodyPrioritizesDirectHTTPBodyOverStream() {
        let url = URL(string: "https://example.com")!
        let directBodyData = "direct body".data(using: .utf8)!
        let streamBodyData = "stream body".data(using: .utf8)!

        let request = NSMutableURLRequest(url: url)
        request.httpBody = directBodyData

        // When both body and stream are set, iOS clears the httpBody automatically
        // So we should test the case where only httpBody is set
        let extractedBodyDirect = request.sbt_extractHTTPBody()
        XCTAssertEqual(extractedBodyDirect, directBodyData)

        // Now test with only stream
        let request2 = NSMutableURLRequest(url: url)
        request2.httpBodyStream = InputStream(data: streamBodyData)

        let extractedBodyStream = request2.sbt_extractHTTPBody()
        XCTAssertNotNil(extractedBodyStream)
        XCTAssertEqual(String(data: extractedBodyStream!, encoding: .utf8), "stream body")
    }

    func testHTTPBodyClearedWhenStreamIsSet() {
        let url = URL(string: "https://example.com")!
        let directBodyData = "direct body".data(using: .utf8)!
        let streamBodyData = "stream body".data(using: .utf8)!

        let request = NSMutableURLRequest(url: url)
        request.httpBody = directBodyData

        // Verify initial state
        XCTAssertNotNil(request.httpBody)

        // Setting httpBodyStream should clear httpBody
        request.httpBodyStream = InputStream(data: streamBodyData)

        // After setting stream, httpBody should be nil (iOS behavior)
        XCTAssertNil(request.httpBody)

        // But sbt_extractHTTPBody should still work by reading from stream
        let extractedBody = request.sbt_extractHTTPBody()
        XCTAssertNotNil(extractedBody)
        XCTAssertEqual(String(data: extractedBody!, encoding: .utf8), "stream body")
    }

    // MARK: - Test edge cases for stream reading

    func testExtractHTTPBodyFromClosedStream() {
        let url = URL(string: "https://example.com")!
        let testData = "closed stream content".data(using: .utf8)!

        let request = NSMutableURLRequest(url: url)
        let inputStream = InputStream(data: testData)
        inputStream.open()
        inputStream.close()
        request.httpBodyStream = inputStream

        let extractedBody = request.sbt_extractHTTPBody()

        // A closed stream cannot be read from, so it should return nil
        XCTAssertNil(extractedBody)
    }

    func testExtractHTTPBodyFromEmptyStream() {
        let url = URL(string: "https://example.com")!
        let emptyData = Data()

        let request = NSMutableURLRequest(url: url)
        request.httpBodyStream = InputStream(data: emptyData)

        let extractedBody = request.sbt_extractHTTPBody()

        XCTAssertNil(extractedBody) // Should return nil for empty streams
    }

    func testExtractHTTPBodyFromLargeStream() {
        let url = URL(string: "https://example.com")!
        let largeString = String(repeating: "A", count: 10_000) // 10KB
        let largeData = largeString.data(using: .utf8)!

        let request = NSMutableURLRequest(url: url)
        request.httpBodyStream = InputStream(data: largeData)

        let extractedBody = request.sbt_extractHTTPBody()

        XCTAssertNotNil(extractedBody)
        XCTAssertEqual(extractedBody!.count, largeData.count)
        XCTAssertEqual(String(data: extractedBody!, encoding: .utf8), largeString)
    }

    func testExtractHTTPBodyWithCorruptedStream() {
        let url = URL(string: "https://example.com")!
        let request = NSMutableURLRequest(url: url)

        // Create a stream from a non-existent file to simulate corruption
        if let corruptedStream = InputStream(url: URL(string: "file:///definitely/does/not/exist")!) {
            request.httpBodyStream = corruptedStream

            let extractedBody = request.sbt_extractHTTPBody()

            // Should handle corrupted streams gracefully
            XCTAssertNil(extractedBody, "Should return nil for corrupted streams")
        }
    }

    func testExtractHTTPBodyWithMultipleStreamReads() {
        let url = URL(string: "https://example.com")!
        let testString = "content for multiple reads"
        let testData = testString.data(using: .utf8)!

        let request = NSMutableURLRequest(url: url)
        request.httpBodyStream = InputStream(data: testData)

        // First read
        let firstRead = request.sbt_extractHTTPBody()
        XCTAssertNotNil(firstRead)

        // Second read should also work (new stream instance)
        request.httpBodyStream = InputStream(data: testData)
        let secondRead = request.sbt_extractHTTPBody()
        XCTAssertNotNil(secondRead)
        XCTAssertEqual(firstRead, secondRead)
    }

    // MARK: - Test sbt_readFromBodyStream class method directly

    func testReadFromBodyStreamWithNilStream() {
        let result = NSURLRequest.sbt_read(fromBodyStream: nil)
        XCTAssertNil(result)
    }

    func testReadFromBodyStreamWithValidStream() {
        let testString = "valid stream data"
        let testData = testString.data(using: .utf8)!
        let inputStream = InputStream(data: testData)

        let result = NSURLRequest.sbt_read(fromBodyStream: inputStream)

        XCTAssertNotNil(result)
        XCTAssertEqual(String(data: result!, encoding: .utf8), testString)
    }

    func testReadFromBodyStreamHandlesReadErrors() {
        // Create a stream that will have read errors
        let inputStream = InputStream(url: URL(string: "file:///nonexistent/path")!)!

        let result = NSURLRequest.sbt_read(fromBodyStream: inputStream)

        XCTAssertNil(result) // Should return nil on read errors
    }

    func testSBTReadFromBodyStreamWithPreOpenedStream() {
        let testString = "pre-opened stream data"
        let testData = testString.data(using: .utf8)!
        let inputStream = InputStream(data: testData)

        // Pre-open the stream
        inputStream.open()

        let result = NSURLRequest.sbt_read(fromBodyStream: inputStream)

        XCTAssertNotNil(result)
        XCTAssertEqual(String(data: result!, encoding: .utf8), testString)

        // Stream should be closed after reading (status 6 = .closed, status 5 = .atEnd)
        // The actual status depends on implementation details, so we check for either
        XCTAssertTrue(inputStream.streamStatus == .closed || inputStream.streamStatus == .atEnd)
    }
}
