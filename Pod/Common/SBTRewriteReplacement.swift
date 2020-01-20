// SBTRewriteReplacement.swift
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
public class SBTRewriteReplacement: NSObject, NSCoding, NSCopying {
    private let findData: Data
    private let replaceData: Data
    
    public override var description: String {
        let findString = String(decoding: findData, as: UTF8.self)
        let replaceString = String(decoding: replaceData, as: UTF8.self)
        
        return "`\(findString)` -> `\(replaceString)`"
    }
    
    @available(*, unavailable)
    override init() {
        fatalError()
    }
    
    @objc public func encode(with coder: NSCoder) {
        coder.encode(findData, forKey: "findData")
        coder.encode(replaceData, forKey: "replaceData")
    }
    
    @objc public required init?(coder: NSCoder) {
        guard let findData = coder.decodeObject(forKey: "findData") as? Data,
            let replaceData = coder.decodeObject(forKey: "replaceData") as? Data else {
            return nil
        }
        
        self.findData = findData
        self.replaceData = replaceData
    }
    
    /**
     *  Initializer
     *
     *  @param find a string regex that search for a string
     *  @param replace a string that replaces the string matched by find
     */
    @objc(initWithFind:replace:)
    public init(find: String, replace: String) {
        self.findData = Data(find.utf8)
        self.replaceData = Data(replace.utf8)
    }
    
    @objc public func copy(with zone: NSZone? = nil) -> Any {
        let findString = String(decoding: findData, as: UTF8.self)
        let replaceString = String(decoding: replaceData, as: UTF8.self)
        
        let copy = SBTRewriteReplacement(find: findString, replace: replaceString)
        return copy
    }
    
    /**
     *  Process a string by applying replacement specified in initializer
     *
     *  @param string string to replace
     */
    @objc(replace:)
    public func replace(string: String) -> String {
        let findString = String(decoding: findData, as: UTF8.self)
        let replaceString = String(decoding: replaceData, as: UTF8.self)
        
        do {
            let regex = try NSRegularExpression(pattern: findString, options: .caseInsensitive)
            return regex.stringByReplacingMatches(in: string, options: [], range: NSRange(location: 0, length: string.count), withTemplate: replaceString)
        } catch {
            return "invalid-regex"
        }
    }
}
