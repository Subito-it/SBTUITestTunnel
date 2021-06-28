// SBTRewriteReplacement.h
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

// Alternative approach to fix this: https://github.com/AliSoftware/OHHTTPStubs/pull/166

@import Foundation;

@interface SBTRewriteReplacement: NSObject<NSCoding, NSCopying>

/**
 *  Initializer
 *
 *  @param find a string regex that search for a string
 *  @param replace a string that replaces the string matched by find
 */
- (nonnull instancetype)initWithFind:(nonnull NSString *)find
                              replace:(nonnull NSString *)replace;

- (nonnull instancetype) __unavailable init;

/**
 *  Process a string by applying replacement specified in initializer
 *
 *  @param string string to replace
 */
- (nonnull NSString *)replace:(nonnull NSString *)string;


@end
