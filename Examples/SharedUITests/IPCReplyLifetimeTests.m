// IPCReplyLifetimeTests.m
//
// Copyright (C) 2026 Subito.it S.r.l (www.subito.it)
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

#import <XCTest/XCTest.h>

#import "../../Sources/SBTUITestTunnelCommon/DetoxIPC/Apple/NSConnection.h"
#import "../../Sources/SBTUITestTunnelCommon/DetoxIPC/DTXIPCConnection-Private.h"
#import "../../Sources/SBTUITestTunnelCommon/DetoxIPC/_DTXIPCExportedObject.h"
#import "../../Sources/SBTUITestTunnelCommon/DetoxIPC/_DTXIPCRemoteBlockRegistry.h"

// Record the synchronous proxy's wait and enqueue events without starting a
// second process. The real registry and invocation decoder remain in use.
@interface SBTReplyWaitObserver : NSObject
@property (nonatomic) NSInteger pendingReplies;
@property (nonatomic) BOOL releasedBeforeEnqueue;
@property (nonatomic, strong) _DTXIPCExportedObject *queuedReply;
@end

@implementation SBTReplyWaitObserver
- (void)_enterReplyBlock { self.pendingReplies += 1; }
- (void)_leavelReplyBlock
{
    self.pendingReplies -= 1;
    self.releasedBeforeEnqueue = self.queuedReply == nil;
}
- (BOOL)_enqueueSynchronousExportedObjectInvocation:(_DTXIPCExportedObject *)reply
{
    self.queuedReply = reply;
    return YES;
}
@end

// Inject remote cleanup when decoding begins, after dispatch has looked up
// the callback. This deterministically reproduces the CI race's ordering.
@interface SBTCleanupDuringReplyDecoding : NSDictionary
- (instancetype)initWithReply:(NSDictionary *)reply cleanup:(dispatch_block_t)cleanup;
@end

@implementation SBTCleanupDuringReplyDecoding {
    NSDictionary *_reply;
    dispatch_block_t _cleanup;
}
- (instancetype)initWithReply:(NSDictionary *)reply cleanup:(dispatch_block_t)cleanup
{
    self = [super init];
    if (self) {
        _reply = reply;
        _cleanup = [cleanup copy];
    }
    return self;
}
- (NSUInteger)count { return _reply.count; }
- (NSEnumerator *)keyEnumerator { return _reply.keyEnumerator; }
- (id)objectForKey:(id)key
{
    if ([key isEqual:@"blockCall"] && _cleanup != nil) {
        dispatch_block_t cleanup = _cleanup;
        _cleanup = nil;
        cleanup();
    }
    return _reply[key];
}
@end

@interface IPCReplyLifetimeTests : XCTestCase
@property (nonatomic, strong) DTXIPCConnection *connection;
@end

@implementation IPCReplyLifetimeTests
- (void)setUp
{
    [super setUp];
    self.connection = [[DTXIPCConnection alloc] initWithServiceName:NSUUID.UUID.UUIDString];
}
- (void)tearDown
{
    [self.connection invalidate];
    self.connection = nil;
    [super tearDown];
}
- (NSDictionary *)replyForIdentifier:(NSString *)identifier
{
    return @{@"blockCall": @YES, @"remoteBlockIdentifier": identifier, @"arguments": @[NSNull.null]};
}
- (void)testCleanupDuringDecodingKeepsReplyAliveUntilEnqueued
{
    __block NSUInteger calls = 0;
    SBTReplyWaitObserver *observer = [SBTReplyWaitObserver new];
    NSString *identifier = [_DTXIPCRemoteBlockRegistry registerRemoteBlock:^{ calls += 1; }
        distantObject:(_DTXIPCDistantObject *)observer];
    NSDictionary *reply = [[SBTCleanupDuringReplyDecoding alloc]
        initWithReply:[self replyForIdentifier:identifier]
        cleanup:^{ [_DTXIPCRemoteBlockRegistry releaseRemoteBlock:identifier]; }];

    [(id<_DTXIPCImpl>)self.connection _invokeRemoteBlock:reply];

    XCTAssertFalse(observer.releasedBeforeEnqueue);
    XCTAssertEqual(observer.pendingReplies, 0);
    XCTAssertNotNil(observer.queuedReply);
    XCTAssertNil([_DTXIPCRemoteBlockRegistry remoteBlockForIdentifier:identifier distantObject:NULL]);
    XCTAssertEqual(calls, 0u);
    [observer.queuedReply invoke];
    XCTAssertEqual(calls, 1u);
}
- (void)testAlreadyReleasedReplyDoesNotCrash
{
    __block NSUInteger calls = 0;
    NSString *identifier = [_DTXIPCRemoteBlockRegistry registerRemoteBlock:^{ calls += 1; } distantObject:nil];
    [_DTXIPCRemoteBlockRegistry releaseRemoteBlock:identifier];

    [(id<_DTXIPCImpl>)self.connection _invokeRemoteBlock:[self replyForIdentifier:identifier]];

    XCTAssertEqual(calls, 0u);
}
- (void)testAsynchronousReplyRemainsRegisteredUntilRemoteCleanup
{
    __block NSUInteger calls = 0;
    NSString *identifier = [_DTXIPCRemoteBlockRegistry registerRemoteBlock:^{ calls += 1; } distantObject:nil];

    [(id<_DTXIPCImpl>)self.connection _invokeRemoteBlock:[self replyForIdentifier:identifier]];

    XCTAssertEqual(calls, 1u);
    XCTAssertNotNil([_DTXIPCRemoteBlockRegistry remoteBlockForIdentifier:identifier distantObject:NULL]);
    [_DTXIPCRemoteBlockRegistry releaseRemoteBlock:identifier];
    XCTAssertNil([_DTXIPCRemoteBlockRegistry remoteBlockForIdentifier:identifier distantObject:NULL]);
}
@end
