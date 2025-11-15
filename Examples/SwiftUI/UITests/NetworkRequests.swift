// NetworkRequests.swift
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

class NetworkRequests: NSObject {
    public var sessionData: Data?
    public var sessionResponse: HTTPURLResponse?
    public var sessionTask: URLSessionTask?

    private let doneSynchQueue = DispatchQueue(label: "NetworkRequests.done.synch.queue")
    private var _done: Bool = false
    fileprivate var done: Bool {
        get {
            doneSynchQueue.sync { _done }
        }
        set {
            doneSynchQueue.sync { _done = newValue }
        }
    }

    private func returnDictionary(status: Int?, headers: [String: String]? = [:], data: Data?) -> [String: Any] {
        ["responseCode": status ?? 0,
         "responseHeaders": headers ?? [:],
         "data": data?.base64EncodedString() ?? ""] as [String: Any]
    }

    func isStubbed(_ result: [String: Any], expectedStubValue: Int) -> Bool {
        let networkJson = json(result)
        let stubValue = networkJson["stubbed"] as? Int
        return stubValue == expectedStubValue
    }

    func isNotConnectedError(_ result: [String: Any]) -> Bool {
        let errorLocalizedDescriptionRaw = result["data"] as! String

        let decodedData = Data(base64Encoded: errorLocalizedDescriptionRaw)!
        let decodedString = String(decoding: decodedData, as: UTF8.self)

        return decodedString.contains("NSURLErrorDomain") && decodedString.contains("-1009")
    }

    func json(_ result: [String: Any]) -> [String: Any] {
        let networkBase64 = result["data"] as! String
        if let networkData = Data(base64Encoded: networkBase64) {
            return ((try? JSONSerialization.jsonObject(with: networkData, options: [])) as? [String: Any]) ?? [:]
        }

        return [:]
    }

    func returnCode(_ result: [String: Any]) -> Int {
        result["responseCode"] as? Int ?? -1
    }

    func headers(_ headers: [String: String], isEqual: [String: String]) -> Bool {
        guard headers.count > 0 else { return false }

        var eq = true
        for (k, v) in headers {
            if isEqual[k] != v {
                eq = false
            }
        }

        return eq
    }

    func dataTaskNetwork(urlString: String, httpMethod: String = "GET", httpBody: String? = nil, requestHeaders: [String: String] = [:], delay: TimeInterval = 0.0) -> [String: Any] {
        let (retResponse, retHeaders, retData) = dataTaskNetworkWithResponse(urlString: urlString, httpMethod: httpMethod, httpBody: httpBody, requestHeaders: requestHeaders, delay: delay)

        return returnDictionary(status: retResponse.statusCode, headers: retHeaders, data: retData)
    }

    func dataTaskNetworkWithResponse(urlString: String, httpMethod: String = "GET", httpBody: String? = nil, requestHeaders: [String: String] = [:], delay _: TimeInterval = 0.0) -> (response: HTTPURLResponse, headers: [String: String], data: Data) {
        var retData: Data!
        var retResponse: HTTPURLResponse!
        var retHeaders: [String: String]!

        let url = URL(string: urlString)!
        var request = URLRequest(url: url)

        requestHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        request.httpMethod = httpMethod
        if let httpBody {
            request.httpBody = httpBody.data(using: .utf8)
        }

        let syncQueue = DispatchQueue(label: Self.description())

        done = false
        URLSession.shared.dataTask(with: request) { data, response, _ in
            guard let httpResponse = response as? HTTPURLResponse else { fatalError("Response either nil or invalid") }
            retResponse = httpResponse
            retHeaders = (retResponse?.allHeaderFields as! [String: String])
            retData = data

            syncQueue.sync { self.done = true }
        }.resume()

        while !syncQueue.sync(execute: { done }) {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        }

        return (retResponse, retHeaders, retData)
    }
    
    func asyncDataTaskNetworkWithResponse(urlString: String, httpMethod: String = "GET", httpBody: String? = nil, requestHeaders: [String: String] = [:]) async throws -> (response: HTTPURLResponse, headers: [String: String], data: Data) {
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if let httpBody {
            request.httpBody = httpBody.data(using: .utf8)
        }
        requestHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            fatalError("Response either nil or invalid")
        }
        let headers = httpResponse.allHeaderFields as? [String: String] ?? [:]
        return (httpResponse, headers, data)
    }

    func uploadTaskNetwork(urlString: String, data: Data?, httpMethod: String = "POST", delay _: TimeInterval = 0.0) -> [String: Any] {
        var retData: Data!
        var retResponse: HTTPURLResponse!
        var retHeaders: [String: String]!

        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if let data {
            request.httpBody = data
        }

        done = false
        URLSession.shared.uploadTask(with: request, from: data) {
            data, response, _ in
            DispatchQueue.main.async {
                guard let httpResponse = response as? HTTPURLResponse else { fatalError("Response either nil or invalid") }
                retResponse = httpResponse
                retHeaders = (retResponse?.allHeaderFields as! [String: String])
                retData = data

                self.done = true
            }
        }.resume()

        while !done {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        }

        return returnDictionary(status: retResponse.statusCode, headers: retHeaders, data: retData)
    }

    func downloadTaskNetwork(urlString: String, data: Data? = nil, httpMethod: String, delay _: TimeInterval = 0.0) -> [String: Any] {
        var retData: Data!
        var retResponse: HTTPURLResponse?
        var retHeaders: [String: String]?

        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if let data {
            request.httpBody = data
        }

        done = false
        URLSession.shared.downloadTask(with: request) {
            dataUrl, response, error in
            DispatchQueue.main.async {
                if let error = error as? URLError {
                    print(error.localizedDescription)
                    print(error.errorUserInfo)
                    print(error.errorCode)
                    retData = Data(error.localizedDescription.utf8)
                } else {
                    guard let httpResponse = response as? HTTPURLResponse else { fatalError("Response either nil or invalid") }
                    retResponse = httpResponse
                    retHeaders = (retResponse?.allHeaderFields as! [String: String])
                    if let dataUrl {
                        retData = try? Data(contentsOf: dataUrl)
                    }
                }

                self.done = true
            }
        }.resume()

        while !done {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        }

        return returnDictionary(status: retResponse?.statusCode ?? -1, headers: retHeaders ?? [:], data: retData)
    }

    func backgroundDataTaskNetwork(urlString: String, data: Data?, httpMethod: String, delay _: TimeInterval = 0.0) -> [String: Any] {
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if let data {
            request.httpBody = data
        }

        done = false
        sessionData = Data()
        let configuration = URLSessionConfiguration.background(withIdentifier: "bgSessionConfiguration1")
        sessionTask = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main).dataTask(with: request)
        sessionTask?.resume()

        while !done {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        }

        let retHeaders = sessionResponse?.allHeaderFields as? [String: String]
        return returnDictionary(status: sessionResponse?.statusCode, headers: retHeaders, data: sessionData)
    }

    func backgroundUploadTaskNetwork(urlString: String, fileUrl: URL, httpMethod: String = "POST", httpBody: Bool = false, delay _: TimeInterval = 0.0) -> [String: Any] {
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if httpBody {
            request.httpBody = "The http body".data(using: .utf8)
        }

        done = false
        sessionData = Data()
        let configuration = URLSessionConfiguration.background(withIdentifier: "bgSessionConfiguration2")
        sessionTask = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main).uploadTask(with: request, fromFile: fileUrl)
        sessionTask?.resume()

        while !done {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        }

        let retHeaders = sessionResponse?.allHeaderFields as? [String: String]
        return returnDictionary(status: sessionResponse?.statusCode, headers: retHeaders, data: sessionData)
    }

    func backgroundDownloadTaskNetwork(urlString: String, httpMethod: String, httpBody: Bool = false, delay _: TimeInterval = 0.0) -> [String: Any] {
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if httpBody {
            request.httpBody = "The http body".data(using: .utf8)
        }

        done = false
        sessionData = Data()
        let configuration = URLSessionConfiguration.background(withIdentifier: "bgSessionConfiguration3")
        sessionTask = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main).downloadTask(with: request)
        sessionTask?.resume()

        while !done {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        }

        let retHeaders = sessionResponse?.allHeaderFields as? [String: String]
        return returnDictionary(status: sessionResponse?.statusCode, headers: retHeaders, data: sessionData)
    }
}

extension NetworkRequests: URLSessionTaskDelegate, URLSessionDataDelegate {
    func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError _: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.done = true
        }
    }

    func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
        sessionData?.append(data)
    }

    func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive response: URLResponse, completionHandler _: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else { fatalError("Response either nil or invalid") }
        sessionResponse = httpResponse
    }
}
