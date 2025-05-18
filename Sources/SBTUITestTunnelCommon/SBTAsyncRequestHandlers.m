//  SBTAsyncRequestHandlers.h
//
// Copyright (C) 2025 Subito.it S.r.l (www.subito.it)
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

#import "SBTAsyncRequestHandler.h"
#import "NSURLRequest+HTTPBodyFix.h"

@implementation SBTAsyncRequestHandler

+ (nullable NSData *)extractBodyDataFromRequest:(NSURLRequest *)request {
    if ([request HTTPBody]) {
        return [request HTTPBody];
    } else if ([request HTTPBodyStream]) {
        return [self drainInputStream:[request HTTPBodyStream]];
    } else if ([request respondsToSelector:@selector(sbt_isUploadTaskRequest)] &&
               [request sbt_isUploadTaskRequest] &&
               [request respondsToSelector:@selector(sbt_uploadHTTPBody)]) {
        return [request sbt_uploadHTTPBody];
    }
    return nil;
}

+ (NSData *)drainInputStream:(NSInputStream *)stream {
    if (!stream) return nil;

    NSMutableData *data = [NSMutableData data];
    uint8_t buffer[4096];

    BOOL shouldClose = (stream.streamStatus == NSStreamStatusNotOpen);
    if (shouldClose) {
        [stream open];
    }

    @try {
        NSInteger bytesRead;
        while ((bytesRead = [stream read:buffer maxLength:sizeof(buffer)]) > 0) {
            [data appendBytes:buffer length:bytesRead];
        }
    } @finally {
        if (shouldClose) {
            [stream close];
        }
    }

    return data.length > 0 ? data : nil;
}

@end
