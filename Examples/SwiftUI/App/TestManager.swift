// TestManager.swift
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

protocol Test: Equatable, Hashable {
    var name: String { get }
}

struct NetworkTest: Test {
    let name: String
    let execute: () async throws -> String

    static func makeFetch(name: String, url: URL?) -> NetworkTest {
        NetworkTest(name: name, execute: {
            guard let url else { return "" }
            let dict = try await executeDataTaskRequest(url: url)
            return try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted).base64EncodedString()
        })
    }

    static func makeUpload(name: String, url: URL?, data: Data?, httpMethod: String = "POST", httpBody: Bool = false) -> NetworkTest {
        NetworkTest(name: name, execute: {
            guard let url, let data else { return "" }
            let dict = try await uploadTaskNetwork(url: url, data: data, httpMethod: httpMethod, httpBody: httpBody)
            return try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted).base64EncodedString()
        })
    }

    static func makePost(name: String, url: URL?, httpBody: String?) -> NetworkTest {
        NetworkTest(name: name, execute: {
            guard let url else { return "" }
            let dict = try await postDataTaskRequest(url: url, httpBody: httpBody)
            return try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted).base64EncodedString()
        })
    }

    static func makeRedirect(name: String, url: URL?) -> NetworkTest {
        NetworkTest(name: name, execute: {
            guard let url else { return "" }
            let dict = try await executeDataTaskRequest(url: url)
            return try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted).base64EncodedString()
        })
    }

    static func makeBackgroundUpload(name: String, url: URL?, data: Data?, httpBody: Bool = false) -> NetworkTest {
        NetworkTest(name: name, execute: {
            guard let url, let data else { return "" }
            let dict = try await backgroundUploadTaskNetwork(url: url, data: data, httpBody: httpBody)
            return try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted).base64EncodedString()
        })
    }

    static func executeDataTaskRequest(url: URL) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            let request = URLRequest(url: url)
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let httpResponse = response as? HTTPURLResponse
                let httpStatus = httpResponse?.statusCode
                let httpHeaders = httpResponse?.allHeaderFields as? [String: String]
                let dict = returnDictionary(status: httpStatus, headers: httpHeaders, data: data)
                continuation.resume(returning: dict)
            }.resume()
        }
    }

    static func uploadTaskNetwork(url: URL, data: Data, httpMethod: String, httpBody: Bool) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod
            if httpBody {
                request.httpBody = "The http body".data(using: .utf8)
            }

            URLSession.shared.uploadTask(with: request, from: data) { responseData, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let httpResponse = response as? HTTPURLResponse
                let httpStatus = httpResponse?.statusCode
                let httpHeaders = httpResponse?.allHeaderFields as? [String: String]
                let dict = returnDictionary(status: httpStatus, headers: httpHeaders, data: responseData)
                continuation.resume(returning: dict)
            }.resume()
        }
    }

    static func postDataTaskRequest(url: URL, httpBody: String?) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            if let httpBody {
                request.httpBody = httpBody.data(using: .utf8)
            }

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let httpResponse = response as? HTTPURLResponse
                let httpStatus = httpResponse?.statusCode
                let httpHeaders = httpResponse?.allHeaderFields as? [String: String]
                let dict = returnDictionary(status: httpStatus, headers: httpHeaders, data: data)
                continuation.resume(returning: dict)
            }.resume()
        }
    }

    static func backgroundUploadTaskNetwork(url: URL, data: Data, httpBody: Bool) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            if httpBody {
                request.httpBody = "The http body".data(using: .utf8)
            }

            // For SwiftUI, we'll use regular upload task instead of background task
            // Background tasks require more complex delegate patterns which are better suited for UIKit
            URLSession.shared.uploadTask(with: request, from: data) { responseData, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let httpResponse = response as? HTTPURLResponse
                let httpStatus = httpResponse?.statusCode
                let httpHeaders = httpResponse?.allHeaderFields as? [String: String]
                let dict = returnDictionary(status: httpStatus, headers: httpHeaders, data: responseData)
                continuation.resume(returning: dict)
            }.resume()
        }
    }

    static func returnDictionary(status: Int?, headers: [String: String]? = [:], data: Data?) -> [String: Any] {
        ["responseCode": status ?? 0,
         "responseHeaders": headers ?? [:],
         "data": data?.base64EncodedString() ?? ""] as [String: Any]
    }

    static func == (lhs: NetworkTest, rhs: NetworkTest) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

struct WebSocketTest: Test {
    let name: String
    let execute: () async throws -> String

    static func makeWebSocket(name: String) -> WebSocketTest {
        WebSocketTest(name: name, execute: {
            "WebSocket functionality - Navigate to separate view"
        })
    }

    static func == (lhs: WebSocketTest, rhs: WebSocketTest) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

struct AutocompleteTest: Test {
    let name: String
    let execute: () async throws -> String

    static func makeAutocomplete(name: String) -> AutocompleteTest {
        AutocompleteTest(name: name, execute: {
            "Autocomplete form - Navigate to separate view"
        })
    }

    static func == (lhs: AutocompleteTest, rhs: AutocompleteTest) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

struct CookiesTest: Test {
    let name: String
    let execute: () async throws -> String

    static func makeCookies(name: String) -> CookiesTest {
        CookiesTest(name: name, execute: {
            let dict = try await executeRequestWithCookies()
            return try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted).base64EncodedString()
        })
    }

    static func executeRequestWithCookies() async throws -> [String: Any] {
        guard let url = URL(string: "https://httpbin.org/get") else {
            return ["error": "Invalid URL"]
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Set cookies
        let jar = HTTPCookieStorage.shared
        let cookieHeaderField = ["Set-Cookie": "key=value, key2=value2"]
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: cookieHeaderField, for: url)
        jar.setCookies(cookies, for: url, mainDocumentURL: url)

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        let httpStatus = httpResponse?.statusCode
        let httpHeaders = httpResponse?.allHeaderFields as? [String: String]

        return NetworkTest.returnDictionary(status: httpStatus, headers: httpHeaders, data: data)
    }

    static func == (lhs: CookiesTest, rhs: CookiesTest) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

// Extension test types for UI components
struct ExtensionTest: Test {
    let name: String
    let execute: () async throws -> String

    static func makeExtension(name: String, description: String) -> ExtensionTest {
        ExtensionTest(name: name, execute: {
            "\(description) - Navigate to separate view"
        })
    }

    static func == (lhs: ExtensionTest, rhs: ExtensionTest) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

struct CoreLocationTest: Test {
    let name: String
    let execute: () async throws -> String

    static func makeCoreLocation(name: String) -> CoreLocationTest {
        CoreLocationTest(name: name, execute: {
            "CoreLocation functionality"
        })
    }

    static func == (lhs: CoreLocationTest, rhs: CoreLocationTest) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

struct CrashTest: Test {
    let name: String
    let execute: () async throws -> String

    static func makeCrash(name: String) -> CrashTest {
        CrashTest(name: name, execute: {
            // Don't actually crash in SwiftUI - return message instead
            "Crash test - Would terminate app"
        })
    }

    static func == (lhs: CrashTest, rhs: CrashTest) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

class TestManager {
    lazy var testList: [any Test] = [
        // Basic network requests (4 existing + 7 new network tests)
        NetworkTest.makeFetch(name: "executeDataTaskRequest", url: URL(string: "https://postman-echo.com/get?param1=val1&param2=val2")),
        NetworkTest.makeFetch(name: "executeDataTaskRequest2", url: URL(string: "https://search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search?q=uitests&param3=val3&param4=val4")),
        NetworkTest.makeFetch(name: "executeDataTaskRequest3", url: URL(string: "https://httpbin.org/get?param1=val1&param2=val2")),
        NetworkTest.makePost(name: "executePostDataTaskRequestWithLargeHTTPBody", url: URL(string: "https://httpbin.org/post"), httpBody: String(repeating: "a", count: 20_000)),
        NetworkTest.makeUpload(name: "executeUploadDataTaskRequest", url: URL(string: "https://httpbin.org/post"), data: "This is a test".data(using: .utf8)),
        NetworkTest.makeUpload(name: "executeUploadDataTaskRequest2", url: URL(string: "https://httpbin.org/post"), data: "This is a test".data(using: .utf8), httpMethod: "PUT"),
        NetworkTest.makeBackgroundUpload(name: "executeBackgroundUploadDataTaskRequest", url: URL(string: "https://httpbin.org/post"), data: "This is a test".data(using: .utf8)),
        NetworkTest.makePost(name: "executePostDataTaskRequestWithHTTPBody", url: URL(string: "https://httpbin.org/post"), httpBody: "&param5=val5&param6=val6"),
        NetworkTest.makeUpload(name: "executeUploadDataTaskRequestWithHTTPBody", url: URL(string: "https://httpbin.org/post"), data: "This is a test".data(using: .utf8), httpMethod: "POST", httpBody: true),
        NetworkTest.makeBackgroundUpload(name: "executeBackgroundUploadDataTaskRequestWithHTTPBody", url: URL(string: "https://httpbin.org/post"), data: "This is a test".data(using: .utf8), httpBody: true),
        NetworkTest.makeRedirect(name: "executeRequestWithRedirect", url: URL(string: "https://httpbin.org/redirect-to?url=http%3A%2F%2Fgoogle.com%2F")),

        // Advanced features - WebSocket, Cookies, Extensions, etc.
        WebSocketTest.makeWebSocket(name: "executeWebSocket"),
        AutocompleteTest.makeAutocomplete(name: "showAutocompleteForm"),
        CookiesTest.makeCookies(name: "executeRequestWithCookies"),
        ExtensionTest.makeExtension(name: "showExtensionTable1", description: "Extension Table 1"),
        ExtensionTest.makeExtension(name: "showExtensionTable2", description: "Extension Table 2"),
        ExtensionTest.makeExtension(name: "showExtensionScrollView", description: "Extension ScrollView"),
        CoreLocationTest.makeCoreLocation(name: "showCoreLocationViewController"),
        ExtensionTest.makeExtension(name: "showExtensionCollectionViewVertical", description: "Collection View Vertical"),
        ExtensionTest.makeExtension(name: "showExtensionCollectionViewHorizontal", description: "Collection View Horizontal"),
        CrashTest.makeCrash(name: "crashApp")
    ]
}
