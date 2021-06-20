// SBTRewrite.swift
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

@objc
public class SBTRewrite: NSObject, NSCoding {
    @objc public var urlReplacement: [SBTRewriteReplacement]
    @objc public var requestReplacement: [SBTRewriteReplacement]
    @objc public var responseReplacement: [SBTRewriteReplacement]
    @objc public var requestHeadersReplacement: [String: String]
    @objc public var responseHeadersReplacement: [String: String]
    @objc public var responseStatusCode: Int
    @objc public var activeIterations: Int
    
    public override var description: String {
        var description = [String]()
        
        description += urlReplacement.map { "URL replacement: \($0)" }
        description += responseReplacement.map { "Response body replacement: \($0)" }
        description += responseHeadersReplacement.map { "Response header replacement: `\($0.key)` -> `\($0.value)`" }
        
        if responseStatusCode > -1 {
            description += ["Response code replacement: \(responseStatusCode)"]
        }
        
        description += requestReplacement.map { "Request body replacement: \($0)" }
        description += requestHeadersReplacement.map { "Request header replacement: `\($0.key)` -> `\($0.value)`" }
        if activeIterations > 0 {
            description += ["Iterations left: \(activeIterations)"]
        }
        
        return description.joined(separator: "\n")
    }
    
    @available(*, unavailable)
    override init() {
        fatalError("Unavailable")
    }
    
    /**
     *  Initializer
     *
     *  @param urlReplacement an array or SBTRewriteReplacement objects that will perform replacements on the request URL (host + query)
     *  @param responseReplacement an array or SBTRewriteReplacement objects that will perform replacements on the response body
     *  @param responseHeadersReplacement a dictionary that represents the response headers. Keys not present will be added while existing keys will be replaced. If the value is empty the key will be removed
     *  @param requestReplacement an array or SBTRewriteReplacement objects that will perform replacements on the request body
     *  @param requestHeadersReplacement a dictionary that represents the request headers. Keys not present will be added while existing keys will be replaced. If the value is empty the key will be removed
     *  @param responseStatusCode the response HTTP code to return
     * @param activeIterations the number of times the rewrite will be performed
     */
    @objc public init(urlReplacement: [SBTRewriteReplacement] = [], requestReplacement: [SBTRewriteReplacement] = [], requestHeadersReplacement: [String: String] = [:], responseReplacement: [SBTRewriteReplacement] = [], responseHeadersReplacement: [String: String] = [:], responseStatusCode: Int = -1, activeIterations: Int = 0) {
        self.urlReplacement = urlReplacement
        self.requestReplacement = requestReplacement
        self.responseReplacement = responseReplacement
        self.requestHeadersReplacement = requestHeadersReplacement
        self.responseHeadersReplacement = responseHeadersReplacement
        self.responseStatusCode = responseStatusCode
        self.activeIterations = activeIterations
    }
    
    @objc public func encode(with coder: NSCoder) {
        coder.encode(urlReplacement, forKey: "urlReplacement")
        coder.encode(requestReplacement, forKey: "requestReplacement")
        coder.encode(responseReplacement, forKey: "responseReplacement")
        coder.encode(requestHeadersReplacement, forKey: "requestHeadersReplacement")
        coder.encode(responseHeadersReplacement, forKey: "responseHeadersReplacement")
        coder.encode(responseStatusCode, forKey: "responseCode")
        coder.encode(activeIterations, forKey: "activeIterations")
    }
    
    @objc public required init?(coder: NSCoder) {
        guard let urlReplacement = coder.decodeObject(forKey: "urlReplacement") as? [SBTRewriteReplacement],
            let requestReplacement = coder.decodeObject(forKey: "requestReplacement") as? [SBTRewriteReplacement],
            let responseReplacement = coder.decodeObject(forKey: "responseReplacement") as? [SBTRewriteReplacement],
            let requestHeadersReplacement = coder.decodeObject(forKey: "requestHeadersReplacement") as? [String: String],
            let responseHeadersReplacement = coder.decodeObject(forKey: "responseHeadersReplacement") as? [String: String] else {
            return nil
        }
        
        self.urlReplacement = urlReplacement
        self.requestReplacement = requestReplacement
        self.responseReplacement = responseReplacement
        self.requestHeadersReplacement = requestHeadersReplacement
        self.responseHeadersReplacement = responseHeadersReplacement
        self.responseStatusCode = coder.decodeInteger(forKey: "responseCode")
        self.activeIterations = coder.decodeInteger(forKey: "activeIterations")
    }
    
    /**
     *  Process a url by applying replacement specified in initializer
     *
     *  @param url url to replace
     */
    @objc(rewriteUrl:)
    public func rewrite(url: URL) -> URL {
        guard urlReplacement.isEmpty == false else { return url }
        
        var absoluteString = url.absoluteString
        urlReplacement.forEach { absoluteString = $0.replace(string: absoluteString) }
        
        return URL(string: absoluteString) ?? url
    }
    
    /**
     *  Process a dictionary of request headers by applying replacement specified in initializer
     *
     *  @param requestHeaders request headers to replace
     */
    @objc(rewriteRequestHeaders:)
    public func rewrite(requestHeaders: [String: String]) -> [String: String] {
        guard requestHeadersReplacement.isEmpty == false else { return requestHeaders }
        
        var headers = requestHeaders
        for (key, value) in requestHeadersReplacement {
            if value.isEmpty {
                headers.removeValue(forKey: key)
            } else {
                headers[key] = value
            }
        }
        
        return headers
    }
    
    /**
     *  Process a dictionary of response headers by applying replacement specified in initializer
     *
     *  @param responseHeaders response headers to replace
     */
    @objc(rewriteResponseHeaders:)
    public func rewrite(responseHeaders: [String: String]) -> [String: String] {
        guard responseHeadersReplacement.isEmpty == false else { return responseHeaders }
        
        var headers = responseHeaders
        for (key, value) in responseHeadersReplacement {
            if value.isEmpty {
                headers.removeValue(forKey: key)
            } else {
                headers[key] = value
            }
        }
        
        return headers
    }
    
    /**
     *  Process a request body by applying replacement specified in initializer
     *
     *  @param requestBody request body
     */
    @objc(rewriteRequestBody:)
    public func rewrite(requestBody: Data) -> Data {
        guard requestReplacement.isEmpty == false else { return requestBody }
        
        var body = String(decoding: requestBody, as: UTF8.self)
        requestReplacement.forEach { body = $0.replace(string: body) }
        
        return Data(body.utf8)
    }
    
    /**
     *  Process a response body by applying replacement specified in initializer
     *
     *  @param responseBody response body
     */
    @objc(rewriteResponseBody:)
    public func rewrite(responseBody: Data) -> Data {
        guard responseReplacement.isEmpty == false else { return responseBody }
        
        var body = String(decoding: responseBody, as: UTF8.self)
        responseReplacement.forEach { body = $0.replace(string: body) }
        
        return Data(body.utf8)
    }
    
    /**
     *  Process a status code by applying replacement specified in initializer
     *
     *  @param statusCode the status code
     */
    @objc(rewriteStatusCode:)
    public func rewrite(statusCode: Int) -> Int {
        return responseStatusCode < 0 ? statusCode : responseStatusCode
    }
}
