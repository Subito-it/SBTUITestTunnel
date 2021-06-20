// SBTRegularExpressionMatcher.swift
//
// Copyright (C) 2021 Subito.it S.r.l (www.subito.it)
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

class SBTRegularExpressionMatcher: NSObject {
    private let invertMatch: Bool
    private let regex: NSRegularExpression
    
    init(regexString: String) {
        let invertMatch = regexString.hasPrefix("!")
        self.invertMatch = invertMatch
        var pattern = regexString
        if invertMatch {
            pattern.remove(at: regexString.startIndex)
        }
        
        self.regex = try! NSRegularExpression(pattern: pattern, options: [])
    }
    
    func matches(pattern: String) -> Bool {
        let nsPattern = NSString(string: pattern)
        let range = NSMakeRange(0, nsPattern.length)
        let matches = regex.numberOfMatches(in: pattern, options: [], range: range)
        
        return invertMatch ? matches == 0 : matches > 0
    }
}
