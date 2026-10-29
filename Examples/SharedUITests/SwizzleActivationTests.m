// SwizzleActivationTests.m
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
@import SBTUITestTunnelCommon;
@import SBTUITestTunnelServer;

@interface SBTUITestTunnelServer (SwizzleActivationTests)
+ (instancetype)sharedInstance;
+ (void)_connectionlessReset;
- (BOOL)takeOffOnce;
@end

static BOOL SBTProxyInjectedAtLoad;
static BOOL SBTRequestInterceptedAtLoad;
static BOOL SBTOriginalAliasesPresentAtLoad;

// Constructors run after category +load methods, before any test can explicitly
// activate the tunnel. This also works when other suites activate it first.
__attribute__((constructor)) static void SBTRecordInitialSwizzleState(void)
{
    @autoreleasepool {
        SBTProxyInjectedAtLoad = [[NSURLSessionConfiguration defaultSessionConfiguration].protocolClasses containsObject:SBTProxyURLProtocol.class] ||
            [[NSURLSessionConfiguration ephemeralSessionConfiguration].protocolClasses containsObject:SBTProxyURLProtocol.class];

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://example.invalid"]];
        request.HTTPBody = [@"body before activation" dataUsingEncoding:NSUTF8StringEncoding];
        [request sbt_markUploadTaskRequest];
        SBTRequestInterceptedAtLoad = request.HTTPBody == nil;

        SBTOriginalAliasesPresentAtLoad =
            class_getClassMethod(NSURLSessionConfiguration.class, NSSelectorFromString(@"sbt_originalEphemeralSessionConfiguration")) != NULL ||
            class_getInstanceMethod(NSURLSession.class, NSSelectorFromString(@"sbt_originalDataTaskWithRequest:")) != NULL ||
            class_getInstanceMethod(NSURLRequest.class, NSSelectorFromString(@"sbt_originalHTTPBody")) != NULL ||
            class_getInstanceMethod(UIViewController.class, NSSelectorFromString(@"sbt_originalRegisterForPreviewingWithDelegate:sourceView:")) != NULL;
    }
}

static NSArray<NSValue *> *SBTHookImplementations(void)
{
    NSMutableArray<NSValue *> *implementations = [NSMutableArray array];
    NSArray<NSArray *> *hooks = @[
        @[object_getClass(NSURLSessionConfiguration.class), @"defaultSessionConfiguration"],
        @[object_getClass(NSURLSessionConfiguration.class), @"ephemeralSessionConfiguration"],
        @[NSURLSession.class, @"uploadTaskWithRequest:fromData:"],
        @[NSURLSession.class, @"uploadTaskWithRequest:fromFile:"],
        @[NSURLSession.class, @"uploadTaskWithRequest:fromData:completionHandler:"],
        @[NSURLSession.class, @"uploadTaskWithRequest:fromFile:completionHandler:"],
        @[NSURLSession.class, @"dataTaskWithRequest:"],
        @[NSURLSession.class, @"dataTaskWithRequest:completionHandler:"],
        @[NSURLRequest.class, @"HTTPBody"],
        @[NSURLRequest.class, @"copyWithZone:"],
        @[NSURLRequest.class, @"mutableCopyWithZone:"],
        @[UIViewController.class, @"registerForPreviewingWithDelegate:sourceView:"]
    ];
    for (NSArray *hook in hooks) {
        Method method = class_getInstanceMethod(hook[0], NSSelectorFromString(hook[1]));
        [implementations addObject:[NSValue valueWithPointer:method_getImplementation(method)]];
    }
    return implementations;
}

@interface SwizzleActivationTests : XCTestCase
@end

@implementation SwizzleActivationTests

- (void)testLinkingServerLeavesSwizzlesInactive
{
    XCTAssertFalse(SBTProxyInjectedAtLoad);
    XCTAssertFalse(SBTRequestInterceptedAtLoad);
    XCTAssertFalse(SBTOriginalAliasesPresentAtLoad);
}

- (void)testTakeOffWithoutLaunchParametersLeavesImplementationsUnchanged
{
    NSArray *before = SBTHookImplementations();
    XCTAssertFalse([SBTUITestTunnelServer takeOff]);
    XCTAssertEqualObjects(SBTHookImplementations(), before);
}

- (void)testConnectionlessSetupActivatesSwizzlesOnlyOnce
{
    [SBTUITestTunnelServer _connectionlessReset];
    NSArray *installed = SBTHookImplementations();
    for (NSUInteger iteration = 0; iteration < 3; iteration++) {
        [SBTUITestTunnelServer _connectionlessReset];
        XCTAssertEqualObjects(SBTHookImplementations(), installed);
        for (NSURLSessionConfiguration *config in @[[NSURLSessionConfiguration defaultSessionConfiguration], [NSURLSessionConfiguration ephemeralSessionConfiguration]]) {
            NSPredicate *proxy = [NSPredicate predicateWithBlock:^BOOL(Class cls, NSDictionary *bindings) { return cls == SBTProxyURLProtocol.class; }];
            XCTAssertEqual([config.protocolClasses filteredArrayUsingPredicate:proxy].count, 1u);
        }
    }

    NSData *body = [@"original upload body" dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://example.invalid"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = body;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:body];
    XCTAssertNil(task.originalRequest.HTTPBody);
    XCTAssertTrue([task.originalRequest sbt_isUploadTaskRequest]);
    XCTAssertEqualObjects([task.originalRequest sbt_uploadHTTPBody], body);
    [task cancel];
    [session invalidateAndCancel];
}

- (void)testNetworkInterceptionActivationInstallsOnlyNetworkHooks
{
    SEL previewingSelector = NSSelectorFromString(@"registerForPreviewingWithDelegate:sourceView:");
    IMP previewing = method_getImplementation(class_getInstanceMethod(UIViewController.class, previewingSelector));

    [SBTUITestTunnelServer activateNetworkInterception];
    NSArray *installed = SBTHookImplementations();
    [SBTUITestTunnelServer activateNetworkInterception];

    XCTAssertEqualObjects(SBTHookImplementations(), installed);
    XCTAssertEqual(method_getImplementation(class_getInstanceMethod(UIViewController.class, previewingSelector)), previewing);
    for (NSURLSessionConfiguration *config in @[[NSURLSessionConfiguration defaultSessionConfiguration], [NSURLSessionConfiguration ephemeralSessionConfiguration]]) {
        NSPredicate *proxy = [NSPredicate predicateWithBlock:^BOOL(Class cls, NSDictionary *bindings) { return cls == SBTProxyURLProtocol.class; }];
        XCTAssertEqual([config.protocolClasses filteredArrayUsingPredicate:proxy].count, 1u);
    }
}

- (void)testTakeOffWithoutLaunchParametersKeepsActivatedInterceptionRegistered
{
    [SBTUITestTunnelServer activateNetworkInterception];
    XCTAssertFalse([SBTUITestTunnelServer.sharedInstance takeOffOnce]);

    NSString *path = [@"/" stringByAppendingString:NSUUID.UUID.UUIDString];
    SBTRequestMatch *match = [[SBTRequestMatch alloc] initWithURL:path query:nil method:nil body:nil requestHeaders:nil responseHeaders:nil];
    NSString *monitorId = [SBTProxyURLProtocol monitorRequestsMatching:match];

    XCTestExpectation *completion = [self expectationWithDescription:@"Request completed"];
    NSURL *url = [NSURL URLWithString:[@"https://example.invalid" stringByAppendingString:path]];
    [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [completion fulfill];
    }] resume];
    [self waitForExpectations:@[completion] timeout:30.0];

    NSArray<SBTMonitoredNetworkRequest *> *monitored = [SBTProxyURLProtocol monitoredRequestsAll];
    [SBTProxyURLProtocol monitorRequestsRemoveWithId:monitorId];
    [SBTProxyURLProtocol monitoredRequestsFlushAll];

    NSPredicate *matchingURL = [NSPredicate predicateWithBlock:^BOOL(SBTMonitoredNetworkRequest *request, NSDictionary *bindings) {
        return [request.originalRequest.URL isEqual:url] || [request.request.URL isEqual:url];
    }];
    XCTAssertEqual([monitored filteredArrayUsingPredicate:matchingURL].count, 1u);
}

@end
