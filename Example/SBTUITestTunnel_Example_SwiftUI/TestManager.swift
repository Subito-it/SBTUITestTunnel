// TestManager.swift
//
// Copyright (C) 2023 Subito.it S.r.l (www.subito.it)
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
    let execute: (() async throws -> String)

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

    static func executeDataTaskRequest(url: URL) async throws -> [String: Any] {
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = response as? HTTPURLResponse
        let httpStatus = httpResponse?.statusCode
        let httpHeaders = httpResponse?.allHeaderFields as? [String: String]
        let dict = returnDictionary(status: httpStatus, headers: httpHeaders, data: data)
        return dict
    }

    static func uploadTaskNetwork(url: URL, data: Data, httpMethod: String, httpBody: Bool)  async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if httpBody {
            request.httpBody = "The http body".data(using: .utf8)
        }
        let (data, response) = try await URLSession.shared.upload(for: request, from: data)
        let httpResponse = response as? HTTPURLResponse
        let httpStatus = httpResponse?.statusCode
        let httpHeaders = httpResponse?.allHeaderFields as? [String: String]
        let dict = returnDictionary(status: httpStatus, headers: httpHeaders, data: data)
        return dict
    }

    static func returnDictionary(status: Int?, headers: [String: String]? = [:], data: Data?) -> [String: Any] {
        return ["responseCode": status ?? 0,
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

//class AutocompleteTest: BaseTest {}
//class CookiesTest: BaseTest {}
//class Extension1Test: BaseTest {}
//class Extension2Test: BaseTest {}
//class Extension3Test: BaseTest {}
//class Extension4Test: BaseTest {}
//class Extension5Test: BaseTest {}
//class Extension6Test: BaseTest {}

class TestManager {

    lazy var testList: [any Test] = [
        NetworkTest.makeFetch(name: "executeDataTaskRequest", url: URL(string: "https://httpbin.org/get?param1=val1&param2=val2")),
        NetworkTest.makeFetch(name: "executeDataTaskRequest2", url: URL(string: "https://search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search?q=uitests&param3=val3&param4=val4")),
        NetworkTest.makeUpload(name: "executeUploadDataTaskRequest", url: URL(string: "https://httpbin.org/post"), data: "This is a test".data(using: .utf8)),
        NetworkTest.makeUpload(name: "executeUploadDataTaskRequest2", url: URL(string: "https://httpbin.org/post"), data: "This is a test".data(using: .utf8), httpMethod: "PUT"),
    ]
}
