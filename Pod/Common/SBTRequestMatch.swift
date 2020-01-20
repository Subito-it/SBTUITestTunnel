// SBTRequestMatch.swift
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

import Foundation

@objc
public class SBTRequestMatch: NSObject, NSCoding, NSCopying {
    /// A regex that is matched against the request url
    @objc public var url: String?
    /// An array of a regex that are matched against the request query (params in GET and DELETE, body in POST and PUT). Instance will match if all regex are fulfilled. You can specify that a certain query should not match by prefixing it with an exclamation mark `!`
    @objc public var query: [String]?
    /// HTTP method
    @objc public var method: String?
    /// A regex that is matched against the request body
    @objc public var body: String?
    /// A regex that is matched against request headers
    @objc public var requestHeaders: [String: String]?
    /// A regex that is matched against response headers
    @objc public var responseHeaders: [String: String]?
    
    public override var description: String {
        let queryDescription = query != nil ? String(describing: query) : "N/A"
        let requestHeadersDescription = requestHeaders != nil ? String(describing: requestHeaders) : "N/A"
        let responseHeadersDescription = responseHeaders != nil ? String(describing: responseHeaders) : "N/A"
        
        return "URL: \(url ?? "N/A")\nQuery: \(queryDescription)\nMethod: \(method ?? "N/A")\nBody: \(body ?? "N/A")\nRequest headers: \(requestHeadersDescription)\nResponse headers: \(responseHeadersDescription)"
    }
    
    @objc public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(url)
        hasher.combine(query)
        hasher.combine(method)
        hasher.combine(body)
        hasher.combine(requestHeaders)
        hasher.combine(responseHeaders)
        return hasher.finalize()
    }
    
    @objc public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? SBTRequestMatch else { return false }
        
        return url == object.url &&
            query == object.query &&
            method == object.method &&
            body == object.body &&
            requestHeaders == object.requestHeaders &&
            responseHeaders == object.responseHeaders
    }
    
    /**
     *  Initializer
     *
     *  @param url a regex that is matched against the request url
     *  @param query an array of a regex that are matched against the request query (params in GET and DELETE, body in POST and PUT). Instance will match if all regex are fulfilled. You can specify that a certain query should not match by prefixing it with an exclamation mark `!`
     *  @param method HTTP method
     *  @param body a regex that is matched against the request body
     *  @param requestHeaders a regex that is matched against request headers
     *  @param responseHeaders a regex that is matched against response headers
     */
    @objc public init(url: String? = nil, query: [String]? = nil, method: String? = nil, body: String? = nil, requestHeaders: [String: String]? = nil, responseHeaders: [String: String]? = nil) {
        self.url = url
        self.query = query
        self.method = method
        self.body = body
        self.requestHeaders = requestHeaders
        self.responseHeaders = responseHeaders
    }
    
    @objc public func encode(with coder: NSCoder) {
        coder.encode(url, forKey: "url")
        coder.encode(query, forKey: "query")
        coder.encode(method, forKey: "method")
        coder.encode(body, forKey: "body")
        coder.encode(requestHeaders, forKey: "requestHeaders")
        coder.encode(responseHeaders, forKey: "responseHeaders")
    }
    
    @objc public required init?(coder: NSCoder) {
        self.url = coder.decodeObject(forKey: "url") as? String
        self.query = coder.decodeObject(forKey: "query") as? [String]
        self.method = coder.decodeObject(forKey: "method") as? String
        self.body = coder.decodeObject(forKey: "body") as? String
        self.requestHeaders = coder.decodeObject(forKey: "requestHeaders") as? [String: String]
        self.responseHeaders = coder.decodeObject(forKey: "responseHeaders") as? [String: String]
    }
    
    @objc public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SBTRequestMatch(url: url, query: query, method: method, body: body, requestHeaders: requestHeaders, responseHeaders: responseHeaders)
        return copy
    }
    
    @objc public func identifier() -> String {
        var data = NSKeyedArchiver.archivedData(withRootObject: self)
        return SHA1.hexString(from: &data)?.replacingOccurrences(of: " ", with: "-") ?? ""
    }
}
