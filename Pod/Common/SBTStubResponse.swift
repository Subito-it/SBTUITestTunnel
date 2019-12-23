// SBTStubResponse.swift
//
// Copyright (C) 2018 Subito.it S.r.l (www.subito.it)
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

@objc public class SBTStubResponse: NSObject, NSCoding, NSCopying {
    /// Set the default response time for all SBTStubResponses when not specified in intializer. If positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
    @objc public static var defaultResponseTime: TimeInterval {
        get { defaults.responseTime }
        set { defaults.responseTime = newValue }
    }
    
    /// Set the default return code for all SBTStubResponses when not specified in intializer
    @objc public static var defaultReturnCode: Int {
        get { defaults.returnCode }
        set { defaults.returnCode = newValue }
    }
    
    /// Set the default Content-Type to be used when passing NSDictionary's as responses
    @objc public static var defaultDictionaryContentType: String {
        get { defaults.contentTypeDictionary }
        set { defaults.contentTypeDictionary = newValue }
    }
    
    /// Set the default Content-Type to be used when passing NSData's as responses
    @objc public static var defaultDataContentType: String {
        get { defaults.contentTypeData }
        set { defaults.contentTypeData = newValue }
    }
    
    /// Set the default Content-Type to be used when passing NSString's as responses
    @objc public static var defaultStringContentType: String {
        get { defaults.contentTypeString }
        set { defaults.contentTypeString = newValue }
    }
    
    @objc public var data: Data
    @objc public var contentType: String
    /// A dictionary that represents the response headers
    @objc public var headers: [String: String]
    /// The HTTP return code of the stubbed response
    @objc public var returnCode: Int
    /// If positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
    @objc public var responseTime: TimeInterval
    /// The connection error failure code that will be used to when stubbing the URLConnectionDidFail NSError
    @objc public var failureCode: Int
    /// The number of times the stubbing will be performed
    @objc public var activeIterations: Int
    
    // MARK: - Private
    
    private struct ContentType {
        static let json = "application/json"
        static let xml = "application/xml"
        static let text = "text/plain"
        static let data = "application/octet-stream"
        static let html = "text/html"
    }
    
    private struct Defaults {
        var responseTime: TimeInterval = 0.0
        var returnCode: Int = 200
        var contentTypeDictionary = ContentType.json
        var contentTypeString = ContentType.text
        var contentTypeData = ContentType.data
    }
    
    private static var defaults = Defaults()
    
    @objc public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(data)
        hasher.combine(contentType)
        hasher.combine(headers)
        hasher.combine(returnCode)
        hasher.combine(responseTime)
        hasher.combine(failureCode)
        hasher.combine(activeIterations)
        return hasher.finalize()
    }

    @objc public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? SBTStubResponse else { return false }

        return data == object.data &&
            contentType == object.contentType &&
            headers == object.headers &&
            returnCode == object.returnCode &&
            responseTime == object.responseTime &&
            failureCode == object.failureCode &&
            activeIterations == object.activeIterations
    }
    
    // MARK: - Objective-C Initializers
    
    @objc public convenience init(response: Any, headers: [String: String]? = nil, contentType: String? = nil, returnCode: Int = -1, responseTime: TimeInterval, activeIterations: Int = 0) {
        self.init(response: response, headers: headers, contentType: contentType, returnCode: returnCode, responseTime: responseTime as TimeInterval?, activeIterations: activeIterations)
    }

    @objc public convenience init(response: Any, headers: [String: String]? = nil, contentType: String? = nil, returnCode: Int = -1, activeIterations: Int = 0) {
        self.init(response: response, headers: headers, contentType: contentType, returnCode: returnCode, responseTime: nil, activeIterations: activeIterations)
    }

    @objc public convenience init(filename: String, headers: [String: String]? = nil, returnCode: Int = -1, responseTime: TimeInterval, activeIterations: Int = 0) {
        self.init(filename: filename, headers: headers, returnCode: returnCode, responseTime: responseTime, activeIterations: activeIterations)
    }

    @objc public convenience init(filename: String, headers: [String: String]? = nil, returnCode: Int = -1, activeIterations: Int = 0) {
        self.init(filename: filename, headers: headers, returnCode: returnCode, responseTime: nil, activeIterations: activeIterations)
    }
    
    @objc static func makeFailureStubResponse(errorCode: Int, responseTime: TimeInterval, activeIterations: Int = 0) -> SBTStubResponse {
        return makeFailureStubResponse(errorCode: errorCode, responseTime: responseTime as TimeInterval?, activeIterations: activeIterations)
    }

    @objc static func makeFailureStubResponse(errorCode: Int, activeIterations: Int = 0) -> SBTStubResponse {
        return makeFailureStubResponse(errorCode: errorCode, responseTime: nil, activeIterations: activeIterations)
    }

    // MARK: - Initializers
    
    /**
    *  Initializer
    *
    *  @param response an instance of NSDictionary, NSData, NSString that represents the data to be returned
    *  @param headers a dictionary that represents the response headers
    *  @param returnCode the HTTP return code of the stubbed response
    *  @param responseTime if positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
    *  @param activeIterations the number of times the stubbing will be performed
    */
    public init(response: Any, headers: [String: String]? = nil, contentType: String? = nil, returnCode: Int = -1, responseTime: TimeInterval? = nil, activeIterations: Int = 0) {
        let stubContentType: String
        if let contentType = contentType {
            stubContentType = contentType
        } else {
            switch response {
            case is Data:
                stubContentType = SBTStubResponse.defaults.contentTypeData
            case is String:
                stubContentType = SBTStubResponse.defaults.contentTypeString
            case is NSDictionary:
                stubContentType = SBTStubResponse.defaults.contentTypeString
            default:
                fatalError("Invalid response type, expecting Data, String or Dictionary")
            }
        }

        switch response {
        case is Data:
            self.data = response as! Data
        case is String:
            self.data = Data((response as! String).utf8)
        case is NSDictionary:
            do {
                self.data = try JSONSerialization.data(withJSONObject: response as! NSDictionary, options: .prettyPrinted)
            } catch {
                fatalError("Failed to convert stub dictionary to JSON! Got \(error)")
            }
        default:
            fatalError("Invalid response type, expecting Data, String or Dictionary")
        }
        
        var mHeaders = headers ?? [:]
        mHeaders["Content-Type"] = contentType

        self.contentType = stubContentType
        self.headers = mHeaders
        self.returnCode = returnCode
        self.responseTime = responseTime ?? SBTStubResponse.defaults.responseTime
        self.failureCode = 0
        self.activeIterations = activeIterations
    }
    
    /**
    *  Initializer
    *
    *  @param filename the file name with the content to be used for stubbing
    *  @param headers a dictionary that represents the response headers
    *  @param returnCode the HTTP return code of the stubbed response
    *  @param responseTime if positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
    *  @param activeIterations the number of times the stubbing will be performed
    *
    *  contentType will be automatically assigned based on file extension
    *  - .json: application/json
    *  - .xml: application/xml
    *  - .htm*: text/html
    *  - .txt: text/plain
    */
    public convenience init(filename: String, headers: [String: String]? = nil, returnCode: Int = -1, responseTime: TimeInterval? = nil, activeIterations: Int = 0) {
        guard let url = URL(string: filename) else {
            fatalError("Invalid filename provided")
        }
        
        let stubExtension = url.pathExtension
        let stubName = url.deletingPathExtension().lastPathComponent
        
        var stubData: Data?
        if let dataUrl = Bundle(for: type(of: self)).url(forResource: stubName, withExtension: stubExtension) {
            stubData = try? Data(contentsOf: dataUrl)
        }

        if stubData == nil {
            for bundle in Bundle.allBundles {
                if bundle.bundlePath.hasSuffix(".xctest"),
                   let dataUrl = bundle.url(forResource: stubName, withExtension: stubExtension) {
                    stubData = try? Data(contentsOf: dataUrl)
                }
            }
        }
                
        guard stubData != nil else {
            fatalError("No data found in stub")
        }
        
        let contentType: String
        switch stubExtension.lowercased() {
        case "json":
            contentType = ContentType.json
        case "xml":
            contentType = ContentType.xml
        case "txt":
            contentType = ContentType.text
        case "htm", "html":
            contentType = ContentType.html
        default:
            fatalError("Unsupported file extension. Expecting json, xml, txt, htm, html")
        }
        
        self.init(response: stubData!, headers: headers, contentType: contentType, returnCode: returnCode, responseTime: responseTime, activeIterations: activeIterations)
    }
    
    static func makeFailureStubResponse(errorCode: Int, responseTime: TimeInterval? = nil, activeIterations: Int = 0) -> SBTStubResponse {
        let stubResponse = SBTStubResponse(response: "", headers: nil, contentType: nil, returnCode: defaults.returnCode, activeIterations: activeIterations)
        stubResponse.failureCode = errorCode
        return stubResponse
    }
    
    @objc public func encode(with coder: NSCoder) {
        coder.encode(data, forKey: "data")
        coder.encode(contentType, forKey: "contentType")
        coder.encode(headers, forKey: "headers")
        coder.encode(returnCode, forKey: "returnCode")
        coder.encode(responseTime, forKey: "responseTime")
        coder.encode(failureCode, forKey: "failureCode")
        coder.encode(activeIterations, forKey: "activeIterations")
    }
            
    @objc required public init?(coder: NSCoder) {
        guard let data = coder.decodeObject(forKey: "data") as? Data,
              let contentType = coder.decodeObject(forKey: "contentType") as? String,
              let headers = coder.decodeObject(forKey: "headers") as? [String: String] else {
            return nil
        }

        self.data = data
        self.contentType = contentType
        self.headers = headers
        self.returnCode = coder.decodeInteger(forKey: "returnCode")
        self.responseTime = coder.decodeDouble(forKey: "responseTime")
        self.failureCode = coder.decodeInteger(forKey: "failureCode")
        self.activeIterations = coder.decodeInteger(forKey: "activeIterations")
    }
    
    @objc public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SBTStubResponse(response: data, headers: headers, contentType: contentType, returnCode: returnCode, responseTime: responseTime, activeIterations: activeIterations)
        return copy
    }
    
    // MARK: - Default overriders
    
    /// Reset defaults values of responseTime, returnCode and contentTypes
    public static func resetUnspecifiedDefaults() {
        defaults = Defaults()
    }
}
