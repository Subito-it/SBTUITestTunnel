//
//  NetworkRequests.swift
//  SBTUITestTunnel_Tests
//
//  Created by Tomas Camin on 02/03/2018.
//  Copyright © 2018 Tomas Camin. All rights reserved.
//

import Foundation

class NetworkRequests: NSObject {
    public var sessionData: Data? = nil
    public var sessionResponse: HTTPURLResponse? = nil
    public var sessionTask: URLSessionTask? = nil
    
    private let doneSynchQueue = DispatchQueue(label: "NetworkRequests.done.synch.queue")
    private var _done: Bool = false
    fileprivate var done: Bool {
        get {
            return doneSynchQueue.sync { return _done }
        }
        set {
            doneSynchQueue.sync { _done = newValue }
        }
    }
    
    private func returnDictionary(status: Int?, headers: [String: String]? = [:], data: Data?) -> [String: Any] {
        return ["responseCode": status ?? 0,
                "responseHeaders": headers ?? [:],
                "data": data?.base64EncodedString() ?? ""] as [String : Any]
    }
    
    func isStubbed(_ result: [String: Any]) -> Bool {
        let networkJson = json(result)
        return (networkJson["stubbed"] != nil)
    }
    
    func json(_ result: [String: Any]) -> [String: Any] {
        let networkBase64 = result["data"] as! String
        if let networkData = Data(base64Encoded: networkBase64) {
            return ((try? JSONSerialization.jsonObject(with: networkData, options: [])) as? [String: Any]) ?? [:]
        }
        
        return [:]
    }
    
    func returnCode(_ result: [String: Any]) -> Int {
        return result["responseCode"] as? Int ?? -1
    }
    
    func headers(_ headers: [String: String], isEqual: [String: String]) -> Bool {
        var eq = true
        for (k, v) in headers {
            if isEqual[k] != v  {
                eq = false
            }
        }
        
        return eq
    }
    
    func dataTaskNetwork(urlString: String, httpMethod: String = "GET", httpBody: String? = nil, delay: TimeInterval = 0.0) -> [String: Any] {
        var retData: Data! = nil
        var retResponse: HTTPURLResponse! = nil
        var retHeaders: [String: String]! = nil
        
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if let httpBody = httpBody {
            request.httpBody = httpBody.data(using: .utf8)
        }
        
        done = false
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                retResponse = response as! HTTPURLResponse
                retHeaders = retResponse.allHeaderFields as! [String: String]
                retData = data
                
                self.done = true
            }
        }.resume()
        
        while !done {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))
        }
        
        return returnDictionary(status: retResponse.statusCode, headers: retHeaders, data: retData)
    }
    
    func uploadTaskNetwork(urlString: String, data: Data, httpMethod: String = "POST", httpBody: Bool = false, delay: TimeInterval = 0.0) -> [String: Any] {
        var retData: Data! = nil
        var retResponse: HTTPURLResponse! = nil
        var retHeaders: [String: String]! = nil
        
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if httpBody {
            request.httpBody = "The http body".data(using: .utf8)
        }
        
        done = false
        URLSession.shared.uploadTask(with: request, from: data) {
            data, response, error in
            DispatchQueue.main.async {
                retResponse = response as! HTTPURLResponse
                retHeaders = retResponse.allHeaderFields as! [String: String]
                retData = data
                
                self.done = true
            }
        }.resume()
        
        while !done {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))
        }
        
        return returnDictionary(status: retResponse.statusCode, headers: retHeaders, data: retData)
    }

    func downloadTaskNetwork(urlString: String, data: Data, httpMethod: String, httpBody: Bool = false, delay: TimeInterval = 0.0) -> [String: Any] {
        var retData: Data! = nil
        var retResponse: HTTPURLResponse! = nil
        var retHeaders: [String: String]! = nil
        
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if httpBody {
            request.httpBody = "The http body".data(using: .utf8)
        }
        
        done = false
        URLSession.shared.downloadTask(with: request) {
            dataUrl, response, error in
            DispatchQueue.main.async {
                retResponse = response as! HTTPURLResponse
                retHeaders = retResponse.allHeaderFields as! [String: String]
                if let dataUrl = dataUrl {
                    retData = try? Data(contentsOf: dataUrl)
                }
                
                self.done = true
            }
        }.resume()
        
        while !done {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))
        }
        
        return returnDictionary(status: retResponse.statusCode, headers: retHeaders, data: retData)
    }

    func backgroundDataTaskNetwork(urlString: String, data: Data, httpMethod: String, httpBody: Bool = false, delay: TimeInterval = 0.0) -> [String: Any] {
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if httpBody {
            request.httpBody = "The http body".data(using: .utf8)
        }
        
        done = false
        sessionData = Data()
        let configuration = URLSessionConfiguration.background(withIdentifier: "bgSessionConfiguration1")
        sessionTask = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main).dataTask(with: request)
        sessionTask?.resume()
        
        while !done {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))
        }
        
        let retHeaders = sessionResponse?.allHeaderFields as? [String: String]
        return returnDictionary(status: sessionResponse?.statusCode, headers: retHeaders, data: sessionData)
    }

    func backgroundUploadTaskNetwork(urlString: String, fileUrl: URL, httpMethod: String = "POST", httpBody: Bool = false, delay: TimeInterval = 0.0) -> [String: Any] {
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
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))
        }
        
        let retHeaders = sessionResponse?.allHeaderFields as? [String: String]
        return returnDictionary(status: sessionResponse?.statusCode, headers: retHeaders, data: sessionData)
    }

    func backgroundDownloadTaskNetwork(urlString: String, httpMethod: String, httpBody: Bool = false, delay: TimeInterval = 0.0) -> [String: Any] {
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
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))
        }
        
        let retHeaders = sessionResponse?.allHeaderFields as? [String: String]
        return returnDictionary(status: sessionResponse?.statusCode, headers: retHeaders, data: sessionData)
    }
}

extension NetworkRequests: URLSessionTaskDelegate, URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.done = true
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        sessionData?.append(data)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        sessionResponse = response as? HTTPURLResponse
    }
}
