// SBTTableViewController.swift
//
// Copyright (C) 2016 Subito.it S.r.l (www.subito.it)
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

import UIKit

class BaseTest {
    var testSelector: Selector
    
    init(testSelector: Selector) {
        self.testSelector = testSelector
    }
}

class NetworkTest: BaseTest {}
class AutocompleteTest: BaseTest {}
class CookiesTest: BaseTest {}

class SBTTableViewController: UITableViewController {
    
    fileprivate var sessionTask: URLSessionTask!
    fileprivate var sessionSemaphore: DispatchSemaphore?
    fileprivate var sessionData: Data?
    fileprivate var sessionResponse: HTTPURLResponse?
    
    private let testList: [BaseTest] = [NetworkTest(testSelector: #selector(executeDataTaskRequest)),
                                        NetworkTest(testSelector: #selector(executeDataTaskRequest2)),
                                        NetworkTest(testSelector: #selector(executeDataTaskRequest3)),
                                        NetworkTest(testSelector: #selector(executeUploadDataTaskRequest)),
                                        NetworkTest(testSelector: #selector(executeUploadDataTaskRequest2)),
                                        NetworkTest(testSelector: #selector(executeBackgroundUploadDataTaskRequest)),
                                        NetworkTest(testSelector: #selector(executePostDataTaskRequestWithHTTPBody)),
                                        NetworkTest(testSelector: #selector(executeUploadDataTaskRequestWithHTTPBody)),
                                        NetworkTest(testSelector: #selector(executeBackgroundUploadDataTaskRequestWithHTTPBody)),
                                        NetworkTest(testSelector: #selector(executeRequestWithRedirect)),
                                        AutocompleteTest(testSelector: #selector(showAutocompleteForm)),
                                        CookiesTest(testSelector: #selector(executeRequestWithCookies))]

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return testList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if testList[indexPath.row] is NetworkTest {
            cell = tableView.dequeueReusableCell(withIdentifier: "networkConnectionCell", for: indexPath)
        } else if testList[indexPath.row] is AutocompleteTest {
            cell = tableView.dequeueReusableCell(withIdentifier: "autocompleteCell", for: indexPath)
        } else if testList[indexPath.row] is CookiesTest {
            cell = tableView.dequeueReusableCell(withIdentifier: "cookieCell", for: indexPath)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "baseCell", for: indexPath)
        }
        cell.textLabel?.text = testList[indexPath.row].testSelector.description
        cell.accessibilityIdentifier = testList[indexPath.row].testSelector.description
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        perform(testList[indexPath.row].testSelector)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.destination, sender) {
        case (is SBTNetworkTestViewController, is Data):
            let vc = segue.destination as! SBTNetworkTestViewController
            let resultData = sender as! Data
            
            vc.networkResultString = resultData.base64EncodedString()
        default:
            break
        }
    }
}

extension SBTTableViewController: URLSessionTaskDelegate, URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        sessionSemaphore?.signal()
        sessionSemaphore = nil
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        sessionData?.append(data)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        sessionResponse = response as? HTTPURLResponse
    }
}


extension SBTTableViewController {
    func returnDictionary(status: Int?, headers: [String: String]? = [:], data: Data?) -> [String: Any] {
        return ["responseCode": status ?? 0,
                "responseHeaders": headers ?? [:],
                "data": data?.base64EncodedString() ?? ""] as [String : Any]
    }
    
    func dataTaskNetwork(urlString: String, httpMethod: String = "GET", httpBody: String? = nil, delay: TimeInterval = 0.0, shouldPushResult: Bool = true) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) { [weak self] in
            let sem = DispatchSemaphore(value: 0)
            
            let url = URL(string: urlString)!
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod
            if let httpBody = httpBody {
                request.httpBody = httpBody.data(using: .utf8)
            }
            
            var retData: Data! = nil
            var retResponse: HTTPURLResponse! = nil
            var retHeaders: [String: String]! = nil
            
            URLSession.shared.dataTask(with: request) {
                data, response, error in
                
                retResponse = response as? HTTPURLResponse
                retHeaders = retResponse?.allHeaderFields as? [String: String]
                retData = data
                
                sem.signal()
                }
                .resume()
            
            sem.wait()
            
            if shouldPushResult {
                DispatchQueue.main.async { [weak self] in
                    let retDict = self?.returnDictionary(status: retResponse.statusCode, headers: retHeaders, data: retData) ?? [:]
                    self?.performSegue(withIdentifier: "networkSegue", sender: try! JSONSerialization.data(withJSONObject: retDict, options: .prettyPrinted))
                }
            }
        }
    }
    
    func uploadTaskNetwork(urlString: String, data: Data, httpMethod: String = "POST", httpBody: Bool = false, delay: TimeInterval = 0.0, shouldPushResult: Bool = true) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) { [weak self] in
            let sem = DispatchSemaphore(value: 0)
            
            let url = URL(string: urlString)!
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod
            if httpBody {
                request.httpBody = "The http body".data(using: .utf8)
            }

            var retData: Data! = nil
            var retResponse: HTTPURLResponse! = nil
            var retHeaders: [String: String]! = nil
            
            URLSession.shared.uploadTask(with: request, from: data) {
                data, response, error in
                
                retResponse = response as? HTTPURLResponse
                retHeaders = retResponse?.allHeaderFields as? [String: String]
                retData = data
                
                sem.signal()
                }
                .resume()
            
            sem.wait()
            
            if shouldPushResult {
                DispatchQueue.main.async { [weak self] in
                    let retDict = self?.returnDictionary(status: retResponse.statusCode, headers: retHeaders, data: retData) ?? [:]
                    self?.performSegue(withIdentifier: "networkSegue", sender: try! JSONSerialization.data(withJSONObject: retDict, options: .prettyPrinted))
                }
            }
        }
    }
    
    func downloadTaskNetwork(urlString: String, data: Data, httpMethod: String, httpBody: Bool = false, delay: TimeInterval = 0.0, shouldPushResult: Bool = true) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) { [weak self] in
            let sem = DispatchSemaphore(value: 0)
            
            let url = URL(string: urlString)!
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod
            if httpBody {
                request.httpBody = "The http body".data(using: .utf8)
            }
            
            var retData: Data! = nil
            var retResponse: HTTPURLResponse! = nil
            var retHeaders: [String: String]! = nil
            
            URLSession.shared.downloadTask(with: request) {
                dataUrl, response, error in
                
                retResponse = response as? HTTPURLResponse
                retHeaders = retResponse?.allHeaderFields as? [String: String]
                if let dataUrl = dataUrl {
                    retData = try? Data(contentsOf: dataUrl)
                }
                
                sem.signal()
                }
                .resume()
            
            sem.wait()
            
            if shouldPushResult {
              DispatchQueue.main.async { [weak self] in
                    let retDict = self?.returnDictionary(status: retResponse.statusCode, headers: retHeaders, data: retData) ?? [:]
                    self?.performSegue(withIdentifier: "networkSegue", sender: try! JSONSerialization.data(withJSONObject: retDict, options: .prettyPrinted))
                }
            }
        }
    }
    
    func backgroundDataTaskNetwork(urlString: String, data: Data, httpMethod: String, httpBody: Bool = false, delay: TimeInterval = 0.0, shouldPushResult: Bool = true) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.sessionSemaphore = DispatchSemaphore(value: 0)
            
            let url = URL(string: urlString)!
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod
            if httpBody {
                request.httpBody = "The http body".data(using: .utf8)
            }
            
            self?.sessionData = Data()
            let configuration = URLSessionConfiguration.background(withIdentifier: "bgSessionConfiguration1")
            self?.sessionTask = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main).dataTask(with: request)
            self?.sessionTask.resume()
            
            self?.sessionSemaphore?.wait()
            
            if shouldPushResult {
                DispatchQueue.main.async { [weak self] in
                    let retHeaders = self?.sessionResponse?.allHeaderFields as? [String: String]
                    let retDict = self?.returnDictionary(status: self?.sessionResponse?.statusCode, headers: retHeaders, data: self?.sessionData) ?? [:]
                    self?.performSegue(withIdentifier: "networkSegue", sender: try! JSONSerialization.data(withJSONObject: retDict, options: .prettyPrinted))
                }
            }
        }
    }
    
    func backgroundUploadTaskNetwork(urlString: String, fileUrl: URL, httpMethod: String = "POST", httpBody: Bool = false, delay: TimeInterval = 0.0, shouldPushResult: Bool = true) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.sessionSemaphore = DispatchSemaphore(value: 0)
            
            let url = URL(string: urlString)!
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod
            if httpBody {
                request.httpBody = "The http body".data(using: .utf8)
            }
            
            self?.sessionData = Data()
            let configuration = URLSessionConfiguration.background(withIdentifier: "bgSessionConfiguration2")
            self?.sessionTask = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main).uploadTask(with: request, fromFile: fileUrl)
            self?.sessionTask.resume()
            
            self?.sessionSemaphore?.wait()
            
            if shouldPushResult {
              DispatchQueue.main.async { [weak self] in
                        let retHeaders = self?.sessionResponse?.allHeaderFields as? [String: String]
                        let retDict = self?.returnDictionary(status: self?.sessionResponse?.statusCode, headers: retHeaders, data: self?.sessionData) ?? [:]
                        self?.performSegue(withIdentifier: "networkSegue", sender: try! JSONSerialization.data(withJSONObject: retDict, options: .prettyPrinted))
                }
            }
        }
    }
    
    func backgroundDownloadTaskNetwork(urlString: String, httpMethod: String, httpBody: Bool = false, delay: TimeInterval = 0.0, shouldPushResult: Bool = true) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.sessionSemaphore = DispatchSemaphore(value: 0)
            
            let url = URL(string: urlString)!
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod
            if httpBody {
                request.httpBody = "The http body".data(using: .utf8)
            }
            
            self?.sessionData = Data()
            let configuration = URLSessionConfiguration.background(withIdentifier: "bgSessionConfiguration3")
            self?.sessionTask = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main).downloadTask(with: request)
            self?.sessionTask.resume()
            
            self?.sessionSemaphore?.wait()
            
            if shouldPushResult {
                DispatchQueue.main.async { [weak self] in
                    let retHeaders = self?.sessionResponse?.allHeaderFields as? [String: String]
                    let retDict = self?.returnDictionary(status: self?.sessionResponse?.statusCode, headers: retHeaders, data: self?.sessionData) ?? [:]
                    self?.performSegue(withIdentifier: "networkSegue", sender: try! JSONSerialization.data(withJSONObject: retDict, options: .prettyPrinted))
                }
            }
        }
    }
}

extension SBTTableViewController {
    
    @objc func executeDataTaskRequest() {
        dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2")
    }
    
    @objc func executeDataTaskRequest2() {
        dataTaskNetwork(urlString: "https://hookb.in/BYklpoNjkXF202xdPxLb?param3=val3&param4=val4")
    }
    
    @objc func executeDataTaskRequest3() {
        dataTaskNetwork(urlString: "http://httpbin.org/get?param1=val1&param2=val2", httpMethod: "GET", httpBody: nil, delay: 0.0, shouldPushResult: false)
    }
    
    @objc func executeUploadDataTaskRequest() {
        let data = "This is a test".data(using: .utf8)
        uploadTaskNetwork(urlString: "http://httpbin.org/post", data: data!)
    }

    @objc func executeUploadDataTaskRequest2() {
        let data = "This is a test".data(using: .utf8)
        uploadTaskNetwork(urlString: "http://httpbin.org/post", data: data!, httpMethod: "PUT")
    }

    @objc func executeBackgroundUploadDataTaskRequest() {
        let data = "This is a test".data(using: .utf8)
        
        let fileName = String(format: "%@_%@", ProcessInfo.processInfo.globallyUniqueString, "file.txt")
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)!
        
        try! data?.write(to: fileURL)
        
        backgroundUploadTaskNetwork(urlString: "http://httpbin.org/post", fileUrl: fileURL)
    }
    
    @objc func executePostDataTaskRequestWithHTTPBody() {
        dataTaskNetwork(urlString: "http://httpbin.org/post", httpMethod: "POST", httpBody: "&param5=val5&param6=val6")
    }

    @objc func executeUploadDataTaskRequestWithHTTPBody() {
        let data = "This is a test".data(using: .utf8)
        uploadTaskNetwork(urlString: "http://httpbin.org/post", data: data!, httpMethod: "POST", httpBody: true)
    }
    
    @objc func executeBackgroundUploadDataTaskRequestWithHTTPBody() {
        let data = "This is a test".data(using: .utf8)
        
        let fileName = String(format: "%@_%@", ProcessInfo.processInfo.globallyUniqueString, "file.txt")
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)!
        
        try! data?.write(to: fileURL)
        
        backgroundUploadTaskNetwork(urlString: "http://httpbin.org/post", fileUrl: fileURL)
    }
    
    @objc func executeRequestWithRedirect() {
        dataTaskNetwork(urlString: "https://httpbin.org/redirect-to?url=http%3A%2F%2Fgoogle.com%2F")
    }
}

extension SBTTableViewController {
    
    @objc func showAutocompleteForm() {
        self.performSegue(withIdentifier: "autocompleteSegue", sender: nil)
    }
}

extension SBTTableViewController {
    
    func dataTaskNetworkWithCookies(urlString: String, httpMethod: String = "GET", httpBody: String? = nil, delay: TimeInterval = 0.0, shouldPushResult: Bool = true) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) { [weak self] in
            let sem = DispatchSemaphore(value: 0)
            
            let url = URL(string: urlString)!
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod
            if let httpBody = httpBody {
                request.httpBody = httpBody.data(using: .utf8)
            }
            
            var retData: Data! = nil
            var retResponse: HTTPURLResponse! = nil
            var retHeaders: [String: String]! = nil
            
            let jar = HTTPCookieStorage.shared
            let cookieHeaderField = ["Set-Cookie": "key=value, key2=value2"]
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: cookieHeaderField, for: url)
            jar.setCookies(cookies, for: request.url!, mainDocumentURL: request.url!)
            
            URLSession.shared.dataTask(with: request) {
                data, response, error in
                
                retResponse = response as? HTTPURLResponse
                retHeaders = retResponse?.allHeaderFields as? [String: String]
                retData = data
                
                sem.signal()
                }
                .resume()
            
            sem.wait()
            
            if shouldPushResult {
                DispatchQueue.main.async { [weak self] in
                    let retDict = self?.returnDictionary(status: retResponse.statusCode, headers: retHeaders, data: retData) ?? [:]
                    self?.performSegue(withIdentifier: "networkSegue", sender: try! JSONSerialization.data(withJSONObject: retDict, options: .prettyPrinted))
                }
            }
        }
    }
    
    @objc func executeRequestWithCookies() {
        dataTaskNetworkWithCookies(urlString: "http://httpbin.org/get", httpMethod: "GET", httpBody: nil, delay: 0.0, shouldPushResult: false)
    }
}
