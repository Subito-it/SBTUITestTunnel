//
//  CFNetworkMisuseTests.swift
//  SBTUITestTunnel_Tests
//

import Foundation
@testable import SBTUITestTunnelCommon
import XCTest

final class CFNetworkMisuseTests: XCTestCase {
    private let testURL = URL(string: "https://httpbin.org/post")!
    private let testData = "this is a test".data(using: .utf8)

    func testUploadTaskBodyHandling() throws {
        let request = NSMutableURLRequest(url: testURL)
        request.httpMethod = "POST"
        request.httpBody = testData

        let task = URLSession.shared.uploadTask(with: request as URLRequest, from: testData) { _, _, _ in
            XCTFail("This test should not actually make a network request")
        }

        // ensure that the request's original body is saved in NSURLProtocol but not set on the request itself
        let originalRequest = try XCTUnwrap(task.originalRequest as? NSURLRequest)
        XCTAssertNil(originalRequest.httpBody)
        XCTAssertNil(originalRequest.httpBodyStream)
        XCTAssertEqual(originalRequest.sbt_uploadHTTPBody(), testData)
    }

    func testUploadTaskMarking() throws {
        let request = NSMutableURLRequest(url: testURL)
        request.httpMethod = "POST"

        let task = URLSession.shared.uploadTask(with: request as URLRequest, from: testData) { _, _, _ in
            XCTFail("This test should not actually make a network request")
        }

        // ensure that the request is properly marked as an upload
        let originalRequest = try XCTUnwrap(task.originalRequest as? NSURLRequest)
        XCTAssertTrue(originalRequest.sbt_isUploadTaskRequest())
    }

    func testDownloadTaskMarking() throws {
        let request = NSMutableURLRequest(url: testURL)
        request.httpMethod = "GET"

        let task = URLSession.shared.downloadTask(with: request as URLRequest) { _, _, _ in
            XCTFail("This test should not actually make a network request")
        }

        // ensure that the request is not marked as an upload
        let originalRequest = try XCTUnwrap(task.originalRequest as? NSURLRequest)
        XCTAssertFalse(originalRequest.sbt_isUploadTaskRequest())
    }

    func testUploadRequestBodyClearing() throws {
        let request = NSMutableURLRequest(url: testURL)
        request.httpBody = testData

        // ensure that the body fields didn't persist during the copy
        let requestWithoutBody = try XCTUnwrap(request.sbt_copyWithoutBody() as? NSURLRequest)
        XCTAssertNil(requestWithoutBody.httpBody)
        XCTAssertNil(requestWithoutBody.httpBodyStream)
    }
}
