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

// swiftlint:disable implicit_return
// swiftformat:disable redundantReturn

import Foundation

@objc public class SBTStubResponse: NSObject, NSCoding, NSCopying {
    /// Set the default response time for all SBTStubResponses when not specified in intializer. If positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
    @objc public static var defaultResponseTime: TimeInterval {
        get { return defaults.responseTime }
        set { defaults.responseTime = newValue }
    }
    
    /// Set the default return code for all SBTStubResponses when not specified in intializer
    @objc public static var defaultReturnCode: Int {
        get { return defaults.returnCode }
        set { defaults.returnCode = newValue }
    }
    
    /// Set the default Content-Type to be used when passing NSDictionary's as responses
    @objc public static var defaultDictionaryContentType: String {
        get { return defaults.contentTypeDictionary }
        set { defaults.contentTypeDictionary = newValue }
    }
    
    /// Set the default Content-Type to be used when passing NSData's as responses
    @objc public static var defaultDataContentType: String {
        get { return defaults.contentTypeData }
        set { defaults.contentTypeData = newValue }
    }
    
    /// Set the default Content-Type to be used when passing NSString's as responses
    @objc public static var defaultStringContentType: String {
        get { return defaults.contentTypeString }
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
    /// The number of times the stubbing will be performed
    @objc public var activeIterations: Int
    
    // MARK: - Private
    
    enum ContentType: String {
        case json = "application/json"
        case xml = "application/xml"
        case text = "text/plain"
        case data = "application/octet-stream"
        case html = "text/html"
    }
    
    struct Defaults {
        var responseTime: TimeInterval = 0.0
        var returnCode: Int = 200
        var contentTypeDictionary = ContentType.json.rawValue
        var contentTypeString = ContentType.text.rawValue
        var contentTypeData = ContentType.data.rawValue
    }
    
    static var defaults = Defaults()
    
    @objc public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(data)
        hasher.combine(contentType)
        hasher.combine(headers)
        hasher.combine(returnCode)
        hasher.combine(responseTime)
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
            activeIterations == object.activeIterations
    }
    
    // MARK: - Objective-C Initializers
    
    // swiftlint:disable:next function_default_parameter_at_end
    @objc public convenience init(response: Any, headers: [String: String]? = nil, contentType: String? = nil, returnCode: Int = -1, responseTime: TimeInterval, activeIterations: Int = 0) {
        self.init(response: response, headers: headers, contentType: contentType, returnCode: returnCode == -1 ? nil : returnCode, responseTime: responseTime as TimeInterval?, activeIterations: activeIterations)
    }
    
    @objc public convenience init(response: Any, headers: [String: String]? = nil, contentType: String? = nil, returnCode: Int = -1, activeIterations: Int = 0) {
        self.init(response: response, headers: headers, contentType: contentType, returnCode: returnCode == -1 ? nil : returnCode, responseTime: nil, activeIterations: activeIterations)
    }
    
    // swiftlint:disable:next function_default_parameter_at_end
    @objc public convenience init(fileNamed: String, headers: [String: String]? = nil, returnCode: Int = -1, responseTime: TimeInterval, activeIterations: Int = 0) {
        self.init(fileNamed: fileNamed, headers: headers, returnCode: returnCode == -1 ? nil : returnCode, responseTime: responseTime, activeIterations: activeIterations)
    }
    
    @objc public convenience init(fileNamed: String, headers: [String: String]? = nil, returnCode: Int = -1, activeIterations: Int = 0) {
        self.init(fileNamed: fileNamed, headers: headers, returnCode: returnCode == -1 ? nil : returnCode, responseTime: nil, activeIterations: activeIterations)
    }
    
    // MARK: - Initializers
    
    /**
     *  Initializer
     *
     *  @param response an instance of NSDictionary, NSData, NSString that represents the data to be returned
     *  @param headers a dictionary that represents the response headers
     *  @param contentType the content type of the response.
     *                     If the value of this parameter is not `nil`, then the content type will be set to the value provided.
     *                     On the other hand, if this parameter is `nil` and `Content-Type` is provided in `headers`, then the value provided in `headers` will be used.
     *                     The content type will be determined automatically using the type of `response` otherwise.
     *  @param returnCode the HTTP return code of the stubbed response
     *  @param responseTime if positive, the amount of time used to send the entire response. If negative, the rate in KB/s at which to send the response data. Use SBTUITunnelStubsDownloadSpeed* constants
     *  @param activeIterations the number of times the stubbing will be performed
     */
    public init(response: Any, headers: [String: String]? = nil, contentType: String? = nil, returnCode: Int? = nil, responseTime: TimeInterval? = nil, activeIterations: Int = 0) {
        let stubContentType: String
        if let contentType = contentType {
            stubContentType = contentType
        } else if let contentType = headers?["Content-Type"] {
            stubContentType = contentType
        } else {
            switch response {
            case is Data:
                stubContentType = SBTStubResponse.defaults.contentTypeData
            case is String:
                stubContentType = SBTStubResponse.defaults.contentTypeString
            case is NSDictionary:
                stubContentType = SBTStubResponse.defaults.contentTypeDictionary
            default:
                fatalError("Invalid response type, expecting Data, String or Dictionary")
            }
        }
        
        switch response {
        case is Data:
            self.data = response as! Data // swiftlint:disable:this force_cast
        case is String:
            self.data = Data((response as! String).utf8) // swiftlint:disable:this force_cast
        case is NSDictionary:
            do {
                self.data = try JSONSerialization.data(withJSONObject: response as! NSDictionary, options: .prettyPrinted) // swiftlint:disable:this force_cast
            } catch {
                fatalError("Failed to convert stub dictionary to JSON! Got \(error)")
            }
        default:
            fatalError("Invalid response type, expecting Data, String or Dictionary")
        }
        
        self.contentType = stubContentType
        
        var mHeaders = headers ?? [:]
        mHeaders["Content-Type"] = self.contentType
        self.headers = mHeaders
        
        self.returnCode = returnCode ?? SBTStubResponse.defaults.returnCode
        self.responseTime = responseTime ?? SBTStubResponse.defaults.responseTime
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
    public convenience init(fileNamed: String, headers: [String: String]? = nil, returnCode: Int? = nil, responseTime: TimeInterval? = nil, activeIterations: Int = 0) {
        guard let url = URL(string: fileNamed) else {
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
        
        guard let returnStubData = stubData else {
            fatalError("No data found in stub")
        }
        
        let contentType: String
        switch stubExtension.lowercased() {
        case "json":
            contentType = ContentType.json.rawValue
        case "xml":
            contentType = ContentType.xml.rawValue
        case "txt":
            contentType = ContentType.text.rawValue
        case "htm", "html":
            contentType = ContentType.html.rawValue
        default:
            fatalError("Unsupported file extension. Expecting json, xml, txt, htm, html")
        }
        
        self.init(response: returnStubData, headers: headers, contentType: contentType, returnCode: returnCode, responseTime: responseTime, activeIterations: activeIterations)
    }
    
    @objc public func encode(with coder: NSCoder) {
        coder.encode(data, forKey: "data")
        coder.encode(contentType, forKey: "contentType")
        coder.encode(headers, forKey: "headers")
        coder.encode(returnCode, forKey: "returnCode")
        coder.encode(responseTime, forKey: "responseTime")
        coder.encode(activeIterations, forKey: "activeIterations")
    }
    
    @objc public required init?(coder: NSCoder) {
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

@objc public class SBTStubFailureResponse: SBTStubResponse {
    /// The connection error failure code that will be used to when stubbing the URLConnectionDidFail NSError
    @objc public var failureCode: Int
    
    public init(errorCode: Int, responseTime: TimeInterval? = nil, activeIterations: Int = 0) {
        self.failureCode = errorCode
        super.init(response: "", headers: nil, contentType: nil, returnCode: SBTStubResponse.defaults.returnCode, responseTime: responseTime, activeIterations: activeIterations)
    }
    
    // MARK: - Objective-C Initializers
    
    @objc public convenience init(errorCode: Int, responseTime: TimeInterval, activeIterations: Int = 0) {
        self.init(errorCode: errorCode, responseTime: responseTime as TimeInterval?, activeIterations: activeIterations)
    }
    
    @objc public convenience init(errorCode: Int, activeIterations: Int = 0) {
        self.init(errorCode: errorCode, responseTime: nil, activeIterations: activeIterations)
    }
    
    @objc public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(failureCode, forKey: "failureCode")
    }
    
    @objc public required init?(coder: NSCoder) {
        self.failureCode = coder.decodeInteger(forKey: "failureCode")
        super.init(coder: coder)
    }
    
    @objc public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = SBTStubFailureResponse(errorCode: failureCode, responseTime: responseTime, activeIterations: activeIterations)
        return copy
    }
    
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
        guard let object = object as? SBTStubFailureResponse else { return false }
        
        return data == object.data &&
            contentType == object.contentType &&
            headers == object.headers &&
            returnCode == object.returnCode &&
            responseTime == object.responseTime &&
            failureCode == object.failureCode &&
            activeIterations == object.activeIterations
    }
}
