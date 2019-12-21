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

import Foundation

@objc
public class SBTRewrite: NSObject, NSCoding {
    private let urlReplacement: [SBTRewriteReplacement]
    private let requestReplacement: [SBTRewriteReplacement]
    private let responseReplacement: [SBTRewriteReplacement]
    private let requestHeadersReplacement: [String: String]
    private let responseHeadersReplacement: [String: String]
    private let responseCode: Int
    private let activeIterations: Int
    
    override public var description: String {
        var description = [String]()
        
        description += urlReplacement.map { "URL replacement: \($0)" }
        description += responseReplacement.map { "Response body replacement: \($0)" }
        description += responseHeadersReplacement.map { "Response header replacement: `\($0.key)` -> `\($0.value)`" }
        
        if responseCode > -1 {
            description += ["Response code replacement: \(responseCode)"]
        }
        
        description += requestReplacement.map { "Request body replacement: \($0)" }
        description += requestHeadersReplacement.map { "Request header replacement: `\($0.key)` -> `\($0.value)`" }
        
        return description.joined(separator: "\n")
    }

    @available(*, unavailable)
    override init() {
      fatalError()
    }
    
    @objc public init(urlReplacement: [SBTRewriteReplacement] = [], requestReplacement: [SBTRewriteReplacement] = [], requestHeadersReplacement: [String: String] = [:], responseReplacement: [SBTRewriteReplacement] = [], responseHeadersReplacement: [String: String] = [:], responseCode: Int = -1, activeIterations: Int = 0) {
        self.urlReplacement = urlReplacement
        self.requestReplacement = requestReplacement
        self.responseReplacement = responseReplacement
        self.requestHeadersReplacement = requestHeadersReplacement
        self.responseHeadersReplacement = responseHeadersReplacement
        self.responseCode = responseCode
        self.activeIterations = activeIterations
    }

    public func encode(with coder: NSCoder) {
        coder.encode(urlReplacement, forKey: "urlReplacement")
        coder.encode(requestReplacement, forKey: "requestReplacement")
        coder.encode(responseReplacement, forKey: "responseReplacement")
        coder.encode(requestHeadersReplacement, forKey: "requestHeadersReplacement")
        coder.encode(responseHeadersReplacement, forKey: "responseHeadersReplacement")
        coder.encode(responseCode, forKey: "responseCode")
        coder.encode(activeIterations, forKey: "activeIterations")
    }
    
    required public init?(coder: NSCoder) {
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
        self.responseCode = coder.decodeInteger(forKey: "responseCode")
        self.activeIterations = coder.decodeInteger(forKey: "activeIterations")
    }
    
    @objc(rewriteUrl:)
    public func rewrite(url: URL) -> URL {
        guard urlReplacement.count > 0 else { return url }
        
        var absoluteString = url.absoluteString
        requestReplacement.forEach { absoluteString = $0.replace(string: absoluteString) }
        
        return URL(string: absoluteString) ?? url
    }
    
    @objc(rewriteRequestHeaders:)
    public func rewrite(requestHeaders: [String: String]) -> [String: String] {
        guard requestHeadersReplacement.count > 0 else { return requestHeaders }
        
        var headers = requestHeaders
        for (key, value) in requestHeadersReplacement {
            let shouldRemoveKey = value.count == 0
            
            if shouldRemoveKey {
                headers.removeValue(forKey: key)
            } else {
                headers[key] = value
            }
        }
        
        return headers
    }

    @objc(rewriteResponseHeaders:)
    public func rewrite(responseHeaders: [String: String]) -> [String: String] {
        guard responseHeadersReplacement.count > 0 else { return responseHeaders }
        
        var headers = responseHeaders
        for (key, value) in responseHeadersReplacement {
            let shouldRemoveKey = value.count == 0
            
            if shouldRemoveKey {
                headers.removeValue(forKey: key)
            } else {
                headers[key] = value
            }
        }
        
        return headers
    }

    @objc(rewriteRequestBody:)
    public func rewrite(requestBody: Data) -> Data {
        guard requestReplacement.count > 0 else { return requestBody }
        
        var body = String(decoding: requestBody, as: UTF8.self)
        requestReplacement.forEach { body = $0.replace(string: body) }
        
        return Data(body.utf8)
    }
    
    @objc(rewriteResponseBody:)
    public func rewrite(responseBody: Data) -> Data {
        guard responseReplacement.count > 0 else { return responseBody }
        
        var body = String(decoding: responseBody, as: UTF8.self)
        responseReplacement.forEach { body = $0.replace(string: body) }
        
        return Data(body.utf8)
    }

    @objc(rewriteStatusCode:)
    public func rewrite(statusCode: Int) -> Int {
        return responseCode < 0 ? statusCode : responseCode
    }
}
