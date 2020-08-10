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
    
    @objc(matchesRequestHeaders:)
    public func matches(requestHeaders: [String: String]?) -> Bool {
        guard let requestHeaders = requestHeaders,
              let matchRequestHeaders = self.requestHeaders, !matchRequestHeaders.isEmpty else {
            return true
        }
       
        return requestHeaders.matches(expectedHeaders: matchRequestHeaders)
    }

    @objc(matchesResponseHeaders:)
    public func matches(responseHeaders: [String: String]?) -> Bool {
         guard let responseHeaders = responseHeaders,
               let matchResponseHeaders = self.responseHeaders, !matchResponseHeaders.isEmpty else {
             return true
         }
        
         return responseHeaders.matches(expectedHeaders: matchResponseHeaders)
    }
    
    @objc(matchesURLRequest:)
    public func matches(urlRequest: URLRequest?) -> Bool {
        guard let urlRequest = urlRequest else { return false }
        
        if let method = method {
            guard urlRequest.httpMethod == method else { return false }
        }
        
        // See https://github.com/Subito-it/SBTUITestTunnel/commit/11fa1b42e944b6b603da8a955deb906b71bcc1e8#diff-589a4a62fe1a450be8720c0eaa5a467dR373
        // guard matches(requestHeaders:urlRequest.allHTTPHeaderFields) else { return false }
        
        if let url = url {
            if let regex = try? NSRegularExpression(pattern: url, options: [.caseInsensitive]),
               let stringToMatch = urlRequest.url?.absoluteString {
                let matchCount = regex.numberOfMatches(in: stringToMatch, options: [], range: NSRange(location: 0, length: stringToMatch.utf16.count))
                
                guard matchCount > 0 else { return false }
            }
        }
        
        if let query = query {
            if let requestUrl = urlRequest.url {
                let components = URLComponents(url: requestUrl, resolvingAgainstBaseURL: false)
                var queryString = components?.query ?? ""
                queryString = "&" + queryString // prepend & to allow always prepending `&` in SBTMatchRequest's queries
                
                for matchQuery in query {
                    let matcher = SBTRegularExpressionMatcher(regularExpression: matchQuery)
                    guard matcher.matches(queryString) else { return false }
                }
            }
        }

        if let body = body {
            let matcher = SBTRegularExpressionMatcher(regularExpression: body)
            let requestBody = String(decoding: urlRequest.httpBody ?? Data(), as: UTF8.self)

            guard matcher.matches(requestBody) else { return false }
        }

        return true
    }
}

private extension Dictionary where Key == String, Value == String {
    func matches(expectedHeaders: [String: String]) -> Bool {
        for (expectedHeaderKey, expectedValue) in expectedHeaders {
            let keyMatcher = SBTRegularExpressionMatcher(regularExpression: expectedHeaderKey)
            let valueMatcher = SBTRegularExpressionMatcher(regularExpression: expectedValue)
            
            var matchFound = false
            for (headerKey, headerValue) in self {
                if keyMatcher.matches(headerKey) && valueMatcher.matches(headerValue) {
                    matchFound = true
                    break
                }
            }
            
            guard matchFound else {
                return false
            }
        }
        
        return true
    }
}
