// NSURLRequest+HTTPBodyFix.h
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

// Alternative approach to fix this: https://github.com/AliSoftware/OHHTTPStubs/pull/166

@import Foundation;

@interface NSURLRequest (HTTPBodyFix)

/// Reads data from an NSInputStream
+ (NSData *)sbt_readFromBodyStream:(NSInputStream *)stream;

/// Extracts HTTP body data from a request using multiple fallback strategies:
/// 1. Direct HTTPBody property
/// 2. Reading from HTTPBodyStream
/// 3. Upload task body via sbt_uploadHTTPBody (for upload tasks)
/// @return The body data, or nil if no body data is available
- (nullable NSData *)sbt_extractHTTPBody;

/// Determines if this request was originally associated with an upload task
///
/// When true, callers should use `sbt_uploadHTTPBody` to get the original body
/// since `HTTPBody` will always be nil.
- (BOOL)sbt_isUploadTaskRequest;

/// Marks this request as associated with an upload task
- (void)sbt_markUploadTaskRequest;

/// Fetches an upload task's body from NSURLProtocol
- (NSData *)sbt_uploadHTTPBody;

/// Returns a copy of the request without the HTTP body
- (NSURLRequest *)sbt_copyWithoutBody;

@end
