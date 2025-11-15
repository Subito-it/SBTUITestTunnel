//
//  NetworkRequests.swift
//  SBTUITestTunnel_SwiftUI_Tests
//
//  Created by SBTUITestTunnel on 15/11/2024.
//  Copyright © 2024 Tomas Camin. All rights reserved.
//

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
            do {
                if let networkJson = try JSONSerialization.jsonObject(with: networkData, options: []) as? [String: Any] {
                    return networkJson
                }
            } catch {}
        }
        return [:]
    }

    func headers(_ headers1: [String: String], isEqual headers2: [String: String]) -> Bool {
        for (key, value) in headers2 {
            if headers1[key] != value {
                return false
            }
        }
        return true
    }

    func returnCode(_ result: [String: Any]) -> Int {
        result["responseCode"] as? Int ?? 0
    }

    func dataTaskNetwork(urlString: String) -> [String: Any] {
        guard let url = URL(string: urlString) else {
            return returnDictionary(status: nil, data: nil)
        }

        done = false
        sessionData = nil
        sessionResponse = nil

        sessionTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, _ in
            self?.sessionData = data
            self?.sessionResponse = response as? HTTPURLResponse
            self?.done = true
        }

        sessionTask?.resume()

        let startTime = CFAbsoluteTimeGetCurrent()
        while !done, CFAbsoluteTimeGetCurrent() - startTime < 60.0 {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        }

        return returnDictionary(status: sessionResponse?.statusCode, headers: sessionResponse?.allHeaderFields as? [String: String], data: sessionData)
    }

    func uploadTaskNetwork(urlString: String, data: Data?, httpMethod: String = "POST", httpBody: Bool = false) -> [String: Any] {
        guard let url = URL(string: urlString) else {
            return returnDictionary(status: nil, data: nil)
        }

        done = false
        sessionData = nil
        sessionResponse = nil

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if httpBody {
            request.httpBody = "The http body".data(using: .utf8)
        }

        sessionTask = URLSession.shared.uploadTask(with: request, from: data ?? Data()) { [weak self] data, response, _ in
            self?.sessionData = data
            self?.sessionResponse = response as? HTTPURLResponse
            self?.done = true
        }

        sessionTask?.resume()

        let startTime = CFAbsoluteTimeGetCurrent()
        while !done, CFAbsoluteTimeGetCurrent() - startTime < 60.0 {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        }

        return returnDictionary(status: sessionResponse?.statusCode, headers: sessionResponse?.allHeaderFields as? [String: String], data: sessionData)
    }

    func dataTaskNetwork(urlString: String, httpMethod: String = "GET", httpBody: String? = nil, delay: TimeInterval = 0.0) -> [String: Any] {
        if delay > 0 {
            Thread.sleep(forTimeInterval: delay)
        }

        guard let url = URL(string: urlString) else {
            return returnDictionary(status: nil, data: nil)
        }

        done = false
        sessionData = nil
        sessionResponse = nil

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if let httpBody {
            request.httpBody = httpBody.data(using: .utf8)
        }

        sessionTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            self?.sessionData = data
            self?.sessionResponse = response as? HTTPURLResponse
            self?.done = true
        }

        sessionTask?.resume()

        let startTime = CFAbsoluteTimeGetCurrent()
        while !done, CFAbsoluteTimeGetCurrent() - startTime < 60.0 {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        }

        return returnDictionary(status: sessionResponse?.statusCode, headers: sessionResponse?.allHeaderFields as? [String: String], data: sessionData)
    }

    @MainActor
    func asyncDataTaskNetworkWithResponse(urlString: String, httpMethod: String = "GET", httpBody: String? = nil, requestHeaders: [String: String]? = nil) async throws -> [String: Any] {
        guard let url = URL(string: urlString) else {
            return returnDictionary(status: nil, data: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if let httpBody {
            request.httpBody = httpBody.data(using: .utf8)
        }
        if let headers = requestHeaders {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        let httpStatus = httpResponse?.statusCode
        let httpHeaders = httpResponse?.allHeaderFields as? [String: String]

        return returnDictionary(status: httpStatus, headers: httpHeaders, data: data)
    }
}
