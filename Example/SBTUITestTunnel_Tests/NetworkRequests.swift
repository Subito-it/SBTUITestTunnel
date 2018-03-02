//
//  NetworkRequests.swift
//  SBTUITestTunnel_Tests
//
//  Created by Tomas Camin on 02/03/2018.
//  Copyright © 2018 Tomas Camin. All rights reserved.
//

import Foundation

class NetworkRequests {
    private func returnDictionary(status: Int?, headers: [String: String]? = [:], data: Data?) -> [String: Any] {
        return ["responseCode": status ?? 0,
                "responseHeaders": headers ?? [:],
                "data": data?.base64EncodedString() ?? ""] as [String : Any]
    }
    
    func dataTaskNetwork(urlString: String, httpMethod: String = "GET", httpBody: String? = nil, delay: TimeInterval = 0.0, shouldPushResult: Bool = true) -> [String: Any] {
        var retData: Data! = nil
        var retResponse: HTTPURLResponse! = nil
        var retHeaders: [String: String]! = nil
        
        let sem = DispatchSemaphore(value: 0)
        
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if let httpBody = httpBody {
            request.httpBody = httpBody.data(using: .utf8)
        }
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            retResponse = response as! HTTPURLResponse
            retHeaders = retResponse.allHeaderFields as! [String: String]
            retData = data
            
            sem.signal()
            }
            .resume()
        
        sem.wait()
        
        return returnDictionary(status: retResponse.statusCode, headers: retHeaders, data: retData)
    }
    
//    func uploadTaskNetwork(urlString: String, data: Data, httpMethod: String = "POST", httpBody: Bool = false, delay: TimeInterval = 0.0, shouldPushResult: Bool = true) {
//        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) { [weak self] in
//            let sem = DispatchSemaphore(value: 0)
//
//            let url = URL(string: urlString)!
//            var request = URLRequest(url: url)
//            request.httpMethod = httpMethod
//            if httpBody {
//                request.httpBody = "The http body".data(using: .utf8)
//            }
//
//            var retData: Data! = nil
//            var retResponse: HTTPURLResponse! = nil
//            var retHeaders: [String: String]! = nil
//
//            URLSession.shared.uploadTask(with: request, from: data) {
//                data, response, error in
//
//                retResponse = response as! HTTPURLResponse
//                retHeaders = retResponse.allHeaderFields as! [String: String]
//                retData = data
//
//                sem.signal()
//                }
//                .resume()
//
//            sem.wait()
//
//            if shouldPushResult {
//                DispatchQueue.main.async { [weak self] in
//                    let retDict = self?.returnDictionary(status: retResponse.statusCode, headers: retHeaders, data: retData) ?? [:]
//                    self?.performSegue(withIdentifier: "networkSegue", sender: try! JSONSerialization.data(withJSONObject: retDict, options: .prettyPrinted))
//                }
//            }
//        }
//    }
//
//    func downloadTaskNetwork(urlString: String, data: Data, httpMethod: String, httpBody: Bool = false, delay: TimeInterval = 0.0, shouldPushResult: Bool = true) {
//        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) { [weak self] in
//            let sem = DispatchSemaphore(value: 0)
//
//            let url = URL(string: urlString)!
//            var request = URLRequest(url: url)
//            request.httpMethod = httpMethod
//            if httpBody {
//                request.httpBody = "The http body".data(using: .utf8)
//            }
//
//            var retData: Data! = nil
//            var retResponse: HTTPURLResponse! = nil
//            var retHeaders: [String: String]! = nil
//
//            URLSession.shared.downloadTask(with: request) {
//                dataUrl, response, error in
//
//                retResponse = response as! HTTPURLResponse
//                retHeaders = retResponse.allHeaderFields as! [String: String]
//                if let dataUrl = dataUrl {
//                    retData = try? Data(contentsOf: dataUrl)
//                }
//
//                sem.signal()
//                }
//                .resume()
//
//            sem.wait()
//
//            if shouldPushResult {
//                DispatchQueue.main.async { [weak self] in
//                    let retDict = self?.returnDictionary(status: retResponse.statusCode, headers: retHeaders, data: retData) ?? [:]
//                    self?.performSegue(withIdentifier: "networkSegue", sender: try! JSONSerialization.data(withJSONObject: retDict, options: .prettyPrinted))
//                }
//            }
//        }
//    }
//
//    func backgroundDataTaskNetwork(urlString: String, data: Data, httpMethod: String, httpBody: Bool = false, delay: TimeInterval = 0.0, shouldPushResult: Bool = true) {
//        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) { [weak self] in
//            self?.sessionSemaphore = DispatchSemaphore(value: 0)
//
//            let url = URL(string: urlString)!
//            var request = URLRequest(url: url)
//            request.httpMethod = httpMethod
//            if httpBody {
//                request.httpBody = "The http body".data(using: .utf8)
//            }
//
//            self?.sessionData = Data()
//            let configuration = URLSessionConfiguration.background(withIdentifier: "bgSessionConfiguration1")
//            self?.sessionTask = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main).dataTask(with: request)
//            self?.sessionTask.resume()
//
//            self?.sessionSemaphore?.wait()
//
//            if shouldPushResult {
//                DispatchQueue.main.async { [weak self] in
//                    let retHeaders = self?.sessionResponse?.allHeaderFields as? [String: String]
//                    let retDict = self?.returnDictionary(status: self?.sessionResponse?.statusCode, headers: retHeaders, data: self?.sessionData) ?? [:]
//                    self?.performSegue(withIdentifier: "networkSegue", sender: try! JSONSerialization.data(withJSONObject: retDict, options: .prettyPrinted))
//                }
//            }
//        }
//    }
//
//    func backgroundUploadTaskNetwork(urlString: String, fileUrl: URL, httpMethod: String = "POST", httpBody: Bool = false, delay: TimeInterval = 0.0, shouldPushResult: Bool = true) {
//        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) { [weak self] in
//            self?.sessionSemaphore = DispatchSemaphore(value: 0)
//
//            let url = URL(string: urlString)!
//            var request = URLRequest(url: url)
//            request.httpMethod = httpMethod
//            if httpBody {
//                request.httpBody = "The http body".data(using: .utf8)
//            }
//
//            self?.sessionData = Data()
//            let configuration = URLSessionConfiguration.background(withIdentifier: "bgSessionConfiguration2")
//            self?.sessionTask = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main).uploadTask(with: request, fromFile: fileUrl)
//            self?.sessionTask.resume()
//
//            self?.sessionSemaphore?.wait()
//
//            if shouldPushResult {
//                DispatchQueue.main.async { [weak self] in
//                    let retHeaders = self?.sessionResponse?.allHeaderFields as? [String: String]
//                    let retDict = self?.returnDictionary(status: self?.sessionResponse?.statusCode, headers: retHeaders, data: self?.sessionData) ?? [:]
//                    self?.performSegue(withIdentifier: "networkSegue", sender: try! JSONSerialization.data(withJSONObject: retDict, options: .prettyPrinted))
//                }
//            }
//        }
//    }
//
//    func backgroundDownloadTaskNetwork(urlString: String, httpMethod: String, httpBody: Bool = false, delay: TimeInterval = 0.0, shouldPushResult: Bool = true) {
//        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) { [weak self] in
//            self?.sessionSemaphore = DispatchSemaphore(value: 0)
//
//            let url = URL(string: urlString)!
//            var request = URLRequest(url: url)
//            request.httpMethod = httpMethod
//            if httpBody {
//                request.httpBody = "The http body".data(using: .utf8)
//            }
//
//            self?.sessionData = Data()
//            let configuration = URLSessionConfiguration.background(withIdentifier: "bgSessionConfiguration3")
//            self?.sessionTask = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main).downloadTask(with: request)
//            self?.sessionTask.resume()
//
//            self?.sessionSemaphore?.wait()
//
//            if shouldPushResult {
//                DispatchQueue.main.async { [weak self] in
//                    let retHeaders = self?.sessionResponse?.allHeaderFields as? [String: String]
//                    let retDict = self?.returnDictionary(status: self?.sessionResponse?.statusCode, headers: retHeaders, data: self?.sessionData) ?? [:]
//                    self?.performSegue(withIdentifier: "networkSegue", sender: try! JSONSerialization.data(withJSONObject: retDict, options: .prettyPrinted))
//                }
//            }
//        }
//    }
}
