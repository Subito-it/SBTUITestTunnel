
// SBTUITestTunnel_Tests.m
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

#import "SBTUITunneledApplication.h"

@interface SBTUITestTunnel_Tests : XCTestCase
{
    SBTUITunneledApplication *app;
}

@end

@implementation SBTUITestTunnel_Tests

- (void)setUp {
    [super setUp];

    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    app = [[SBTUITunneledApplication alloc] init];
    
    [app launchTunnelWithOptions:@[SBTUITunneledApplicationLaunchOptionResetFilesystem, SBTUITunneledApplicationLaunchOptionInhibitCoreLocation]
                    startupBlock:nil];
    
    // wait for app to start
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"exists == true"] evaluatedWithObject:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] handler:nil];
    [self waitForExpectationsWithTimeout:15.0 handler:nil];
}

- (void)testStartupCommands {
    [app terminate];
    
    app = [[SBTUITunneledApplication alloc] init];
    NSString *randomString = [[NSProcessInfo processInfo] globallyUniqueString];
    [app launchTunnelWithStartupBlock:^() {
        [app keychainSetObject:randomString forKey:@"test_key"];
        [app setUserInterfaceAnimationsEnabled:NO];
    }];
    XCTAssertEqualObjects([app keychainObjectForKey:@"test_key"], randomString);
}

- (void)testKeychainCommands {
    NSString *randomString = [[NSProcessInfo processInfo] globallyUniqueString];
    // add and retrieve random string
    XCTAssertTrue([app keychainSetObject:randomString forKey:@"test_key"]);
    XCTAssertEqualObjects([app keychainObjectForKey:@"test_key"], randomString);
    
    // remove and check for nil
    XCTAssertTrue([app keychainRemoveObjectForKey:@"test_key"]);
    XCTAssertNil([app keychainObjectForKey:@"test_key"]);
    
    // add again, remove all keys and check for nil item
    XCTAssertTrue([app keychainSetObject:randomString forKey:@"test_key"]);
    [app keychainReset];
    XCTAssertNil([app keychainObjectForKey:@"test_key"]);
}

- (void)testNSUserDefaultsCommands {
    NSString *randomString = [[NSProcessInfo processInfo] globallyUniqueString];
    // add and retrieve random string
    XCTAssertTrue([app userDefaultsSetObject:randomString forKey:@"test_key"]);
    XCTAssertEqualObjects([app userDefaultsObjectForKey:@"test_key"], randomString);
    
    // remove and check for nil
    XCTAssertTrue([app userDefaultsRemoveObjectForKey:@"test_key"]);
    XCTAssertNil([app userDefaultsObjectForKey:@"test_key"]);
    
    // add again, remove all keys and check for nil item
    XCTAssertTrue([app userDefaultsSetObject:randomString forKey:@"test_key"]);
    [app userDefaultsReset];
    XCTAssertNil([app userDefaultsObjectForKey:@"test_key"]);
}

- (void)testDownloadUpload {
    NSString *randomString = [[NSProcessInfo processInfo] globallyUniqueString];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *testFilePath = [[paths firstObject] stringByAppendingPathComponent:@"test_file_a.txt"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:testFilePath]) {
        [fm removeItemAtPath:testFilePath error:nil];
    }
    [[randomString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:testFilePath atomically:YES];
    
    [app uploadItemAtPath:testFilePath toPath:@"test_file_b.txt" relativeTo:NSDocumentDirectory];
    
    NSData *uploadData = [app downloadItemFromPath:@"test_file_b.txt" relativeTo:NSDocumentDirectory];
    
    NSString *uploadedString = [[NSString alloc] initWithData:uploadData encoding:NSUTF8StringEncoding];
    
    XCTAssertTrue([randomString isEqualToString:uploadedString]);
}

- (void)testStubCommands {
    NSString *stubId1 = [app stubRequestsWithQueryParams:@[@"p=us", @"l"]
                                   returnJsonDictionary:@{@"request": @"stubbed"}
                                             returnCode:200
                                           responseTime:0.0];
    [self afterTapping:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] assertAlertMessageEquals:@"Stubbed"];
    [app stubRequestsRemoveWithId:stubId1];
    
    NSString *stubId2 = [app stubRequestsWithRegex:@"(.*)google(.*)"
                                  returnJsonNamed:@"googleMockResponse.json"
                                       returnCode:200
                                     responseTime:0.0];
    [self afterTapping:app.buttons[@"https://www.google.com/?q=tennis"] assertAlertMessageEquals:@"Stubbed"];
    [app stubRequestsRemoveWithId:stubId2];
    
    [self afterTapping:app.buttons[@"http://duckduckgo.com/?q=tennis"] assertAlertMessageEquals:@"Not Stubbed"];
    
    [app stubRequestsRemoveAll];
}

- (void)testStubAndRemoveQueryCommands {
    [app stubRequestsWithQueryParams:@[@"p=us", @"l"]
                returnJsonDictionary:@{@"request": @"stubbed"}
                          returnCode:200
                        responseTime:0.0
               removeAfterIterations:2];
    
    [self afterTapping:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] assertAlertMessageEquals:@"Stubbed"];
    [self afterTapping:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] assertAlertMessageEquals:@"Stubbed"];
    [self afterTapping:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] assertAlertMessageEquals:@"Not Stubbed"];
    
    [app stubRequestsRemoveAll];
}

- (void)testStubAndRemoveRegexCommands {
    [app stubRequestsWithRegex:@"(.*)google(.*)"
               returnJsonNamed:@"googleMockResponse.json"
                    returnCode:200
                  responseTime:0.0
         removeAfterIterations:2];
    
    [self afterTapping:app.buttons[@"https://www.google.com/?q=tennis"] assertAlertMessageEquals:@"Stubbed"];
    [self afterTapping:app.buttons[@"https://www.google.com/?q=tennis"] assertAlertMessageEquals:@"Stubbed"];
    [self afterTapping:app.buttons[@"https://www.google.com/?q=tennis"] assertAlertMessageEquals:@"Not Stubbed"];
    
    [app stubRequestsRemoveAll];
}

- (void)testStubRemoval {
    NSString *stubId = [app stubRequestsWithQueryParams:@[@"p=us", @"l"]
                returnJsonDictionary:@{@"request": @"stubbed"}
                          returnCode:200
                        responseTime:0.0];
    
    [self afterTapping:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] assertAlertMessageEquals:@"Stubbed"];
    
    [app stubRequestsRemoveWithId:stubId];

    [self afterTapping:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] assertAlertMessageEquals:@"Not Stubbed"];
}

- (void)testStubResponseDelay {
    NSTimeInterval responseTime = 5.0;
    [app stubRequestsWithQueryParams:@[@"p=us", @"l"]
                returnJsonDictionary:@{@"request": @"stubbed"}
                          returnCode:200
                        responseTime:responseTime];
    
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"exists == true"] evaluatedWithObject:app.alerts.element handler:nil];
    NSTimeInterval start = CFAbsoluteTimeGetCurrent();
    [app.buttons[@"https://us.yahoo.com/?p=us&l=1"] tap];
    [self waitForExpectationsWithTimeout:15.0 handler:nil];
    NSTimeInterval delta = ABS(CFAbsoluteTimeGetCurrent() - start);
    XCTAssertTrue(delta - responseTime > 0 && delta - responseTime < 2.0);
    XCTAssertTrue([[app.alerts[@"Result"] staticTexts][@"Stubbed"] exists]);
    [app.buttons[@"OK"] tap];
    
    [app stubRequestsRemoveAll];
}

- (void)testMonitorFlushRegexCommandsResponseString {
    XCTAssertTrue([app monitoredRequestsFlushAll].count == 0);
    
    [app monitorRequestsWithRegex:@"(.*)google(.*)"];
    
    [self afterTapping:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] assertAlertMessageEquals:@"Not Stubbed"];
    [self afterTapping:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] assertAlertMessageEquals:@"Not Stubbed"];
    XCTAssertTrue([app monitoredRequestsFlushAll].count == 0);
    
    [self afterTapping:app.buttons[@"https://www.google.com/?q=tennis"] assertAlertMessageEquals:@"Not Stubbed"];
    [self afterTapping:app.buttons[@"https://www.google.com/?q=tennis"] assertAlertMessageEquals:@"Not Stubbed"];
    [self afterTapping:app.buttons[@"https://www.google.com/?q=tennis"] assertAlertMessageEquals:@"Not Stubbed"];
    
    NSArray<SBTMonitoredNetworkRequest *> *requests = [app monitoredRequestsFlushAll];
    
    XCTAssertTrue(requests.count == 3);
    
    for (SBTMonitoredNetworkRequest *request in requests) {
        XCTAssertTrue([[request responseString] rangeOfString:@"www.google."].location != NSNotFound);
        XCTAssertTrue(request.timestamp > 0.0);
        XCTAssertTrue(request.requestTime > 0.0);
    }
    
    XCTAssertTrue([app monitoredRequestsFlushAll].count == 0);
    
    [app monitorRequestRemoveAll];
    [self afterTapping:app.buttons[@"https://www.google.com/?q=tennis"] assertAlertMessageEquals:@"Not Stubbed"];

    XCTAssertTrue([app monitoredRequestsFlushAll].count == 0);
}

- (void)testMonitorPeekRegexCommandsResponseString {
    XCTAssertTrue([app monitoredRequestsPeekAll].count == 0);
    
    [app monitorRequestsWithRegex:@"(.*)google(.*)"];
    
    [self afterTapping:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] assertAlertMessageEquals:@"Not Stubbed"];
    [self afterTapping:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] assertAlertMessageEquals:@"Not Stubbed"];
    XCTAssertTrue([app monitoredRequestsPeekAll].count == 0);
    
    [self afterTapping:app.buttons[@"https://www.google.com/?q=tennis"] assertAlertMessageEquals:@"Not Stubbed"];
    [self afterTapping:app.buttons[@"https://www.google.com/?q=tennis"] assertAlertMessageEquals:@"Not Stubbed"];
    [self afterTapping:app.buttons[@"https://www.google.com/?q=tennis"] assertAlertMessageEquals:@"Not Stubbed"];
    
    NSArray<SBTMonitoredNetworkRequest *> *requests = [app monitoredRequestsPeekAll];
    XCTAssertTrue(requests.count == 3);
    NSArray<SBTMonitoredNetworkRequest *> *requests2 = [app monitoredRequestsPeekAll];
    XCTAssertTrue(requests2.count == 3);
    
    for (SBTMonitoredNetworkRequest *request in requests) {
        XCTAssertTrue([[request responseString] rangeOfString:@"www.google."].location != NSNotFound);
        XCTAssertTrue(request.timestamp > 0.0);
        XCTAssertTrue(request.requestTime > 0.0);
    }
    
    [app monitorRequestRemoveAll];
    [self afterTapping:app.buttons[@"https://www.google.com/?q=tennis"] assertAlertMessageEquals:@"Not Stubbed"];
}

- (void)testMonitorQueryCommandsResponseString {
    XCTAssertTrue([app monitoredRequestsFlushAll].count == 0);
    
    [app monitorRequestsWithQueryParams:@[@"p=us", @"np"]];
    [self afterTapping:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] assertAlertMessageEquals:@"Not Stubbed"];
    [self afterTapping:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] assertAlertMessageEquals:@"Not Stubbed"];
    
    XCTAssertTrue([app monitoredRequestsFlushAll].count == 0);
    [app monitorRequestRemoveAll];
    
    [app monitorRequestsWithQueryParams:@[@"p=us", @"l"]];
    
    [self afterTapping:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] assertAlertMessageEquals:@"Not Stubbed"];
    [self afterTapping:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] assertAlertMessageEquals:@"Not Stubbed"];
    [self afterTapping:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] assertAlertMessageEquals:@"Not Stubbed"];
    
    NSArray<SBTMonitoredNetworkRequest *> *requests = [app monitoredRequestsFlushAll];
    
    XCTAssertTrue(requests.count == 3);
    
    for (SBTMonitoredNetworkRequest *request in requests) {
        XCTAssertTrue([[request responseString] rangeOfString:@"www.yahoo."].location != NSNotFound);
        XCTAssertTrue(request.timestamp > 0.0);
        XCTAssertTrue(request.requestTime > 0.0);
    }
    
    XCTAssertTrue([app monitoredRequestsFlushAll].count == 0);
    
    [app monitorRequestRemoveAll];
    [self afterTapping:app.buttons[@"https://www.google.com/?q=tennis"] assertAlertMessageEquals:@"Not Stubbed"];
    
    XCTAssertTrue([app monitoredRequestsFlushAll].count == 0);
}

- (void)testThrottleWithRegexResponseDelay {
    NSTimeInterval responseTime = 5.0;
    [app throttleRequestsWithRegex:@"(.*)google(.*)"
                      responseTime:responseTime];
    
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"exists == true"] evaluatedWithObject:app.alerts.element handler:nil];
    NSTimeInterval start = CFAbsoluteTimeGetCurrent();
    [app.buttons[@"https://www.google.com/?q=tennis"] tap];
    [self waitForExpectationsWithTimeout:15.0 handler:nil];
    NSTimeInterval delta = ABS(CFAbsoluteTimeGetCurrent() - start);
    XCTAssertTrue(delta - responseTime > 0 && delta - responseTime < 2.0);
    XCTAssertTrue([[app.alerts[@"Result"] staticTexts][@"Not Stubbed"] exists]);
    [app.buttons[@"OK"] tap];
    
    [app throttleRequestRemoveAll];
}

- (void)testThrottleWithQueryResponseDelay {
    NSTimeInterval responseTime = 5.0;
    [app throttleRequestsWithQueryParams:@[@"p=us", @"l"]
                            responseTime:responseTime];
    
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"exists == true"] evaluatedWithObject:app.alerts.element handler:nil];
    NSTimeInterval start = CFAbsoluteTimeGetCurrent();
    [app.buttons[@"https://us.yahoo.com/?p=us&l=1"] tap];
    [self waitForExpectationsWithTimeout:15.0 handler:nil];
    NSTimeInterval delta = ABS(CFAbsoluteTimeGetCurrent() - start);
    XCTAssertTrue(delta - responseTime > 0 && delta - responseTime < 2.0);
    XCTAssertTrue([[app.alerts[@"Result"] staticTexts][@"Not Stubbed"] exists]);
    [app.buttons[@"OK"] tap];
    
    [app throttleRequestRemoveAll];
}

- (void)testMonitorAndStubWitRegexCommands {
    [app stubRequestsWithRegex:@"(.*)google(.*)"
               returnJsonNamed:@"googleMockResponse.json"
                    returnCode:200
                  responseTime:0.0];
    [app monitorRequestsWithRegex:@"(.*)google(.*)"];
    
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"exists == true"] evaluatedWithObject:app.alerts.element handler:nil];
    [app.buttons[@"https://www.google.com/?q=tennis"] tap];
    [self waitForExpectationsWithTimeout:15.0 handler:nil];
    
    NSArray<SBTMonitoredNetworkRequest *> *requestsMonitored = [app monitoredRequestsFlushAll];
    XCTAssert(requestsMonitored.count == 1);
    XCTAssertTrue([[app.alerts[@"Result"] staticTexts][@"Stubbed"] exists]);
    [app.buttons[@"OK"] tap];
    
    [app throttleRequestRemoveAll];
}

- (void)testThrottleResponseTimeOverridesRegexStub {
    NSTimeInterval responseTime = 5.0;
    [app stubRequestsWithRegex:@"(.*)google(.*)"
               returnJsonNamed:@"googleMockResponse.json"
                    returnCode:200
                  responseTime:0.0];
    [app throttleRequestsWithRegex:@"(.*)google(.*)"
                      responseTime:responseTime];
    
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"exists == true"] evaluatedWithObject:app.alerts.element handler:nil];
    NSTimeInterval start = CFAbsoluteTimeGetCurrent();
    [app.buttons[@"https://www.google.com/?q=tennis"] tap];
    [self waitForExpectationsWithTimeout:15.0 handler:nil];
    NSTimeInterval delta = ABS(CFAbsoluteTimeGetCurrent() - start);
    XCTAssertTrue(delta - responseTime > 0 && delta - responseTime < 2.0);
    
    XCTAssertTrue([[app.alerts[@"Result"] staticTexts][@"Stubbed"] exists]);
    [app.buttons[@"OK"] tap];
    
    [app throttleRequestRemoveAll];
}

- (void)testMonitorAndThrottleWithQueryCommands {
    [app monitorRequestsWithQueryParams:@[@"p=us", @"l"]];
    NSTimeInterval responseTime = 5.0;
    [app throttleRequestsWithQueryParams:@[@"p=us", @"l"]
                            responseTime:responseTime];
    
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"exists == true"] evaluatedWithObject:app.alerts.element handler:nil];
    NSTimeInterval start = CFAbsoluteTimeGetCurrent();
    [app.buttons[@"https://us.yahoo.com/?p=us&l=1"] tap];
    [self waitForExpectationsWithTimeout:15.0 handler:nil];
    
    NSTimeInterval delta = ABS(CFAbsoluteTimeGetCurrent() - start);
    XCTAssertTrue(delta - responseTime > 0 && delta - responseTime < 2.0);
    XCTAssertTrue([[app.alerts[@"Result"] staticTexts][@"Not Stubbed"] exists]);
    
    NSArray<SBTMonitoredNetworkRequest *> *requestsMonitored = [app monitoredRequestsFlushAll];
    XCTAssert(requestsMonitored.count == 1);
    [app.buttons[@"OK"] tap];
    
    [app throttleRequestRemoveAll];
}

- (void)testMonitorAndThrottleWithRegexCommands {
    [app monitorRequestsWithRegex:@"(.*)google(.*)"];
    NSTimeInterval responseTime = 5.0;
    [app throttleRequestsWithRegex:@"(.*)google(.*)"
                      responseTime:responseTime];
    
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"exists == true"] evaluatedWithObject:app.alerts.element handler:nil];
    NSTimeInterval start = CFAbsoluteTimeGetCurrent();
    [app.buttons[@"https://www.google.com/?q=tennis"] tap];
    [self waitForExpectationsWithTimeout:15.0 handler:nil];
    
    NSTimeInterval delta = ABS(CFAbsoluteTimeGetCurrent() - start);
    XCTAssertTrue(delta - responseTime > 0 && delta - responseTime < 2.0);
    XCTAssertTrue([[app.alerts[@"Result"] staticTexts][@"Not Stubbed"] exists]);
    
    NSArray<SBTMonitoredNetworkRequest *> *requestsMonitored = [app monitoredRequestsFlushAll];
    XCTAssert(requestsMonitored.count == 1);
    [app.buttons[@"OK"] tap];
    
    [app throttleRequestRemoveAll];
}

- (void)testMonitorAndStubWithQueryCommands {
    [app stubRequestsWithQueryParams:@[@"p=us", @"l"]
                returnJsonDictionary:@{@"request": @"stubbed"}
                          returnCode:200
                        responseTime:0.0];
    [app monitorRequestsWithQueryParams:@[@"p=us", @"l"]];
    
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"exists == true"] evaluatedWithObject:app.alerts.element handler:nil];
    [app.buttons[@"https://us.yahoo.com/?p=us&l=1"] tap];
    [self waitForExpectationsWithTimeout:15.0 handler:nil];
    
    NSArray<SBTMonitoredNetworkRequest *> *requestsMonitored = [app monitoredRequestsFlushAll];
    XCTAssert(requestsMonitored.count == 1);
    XCTAssertTrue([[app.alerts[@"Result"] staticTexts][@"Stubbed"] exists]);
    [app.buttons[@"OK"] tap];
    
    [app throttleRequestRemoveAll];
}

- (void)testThrottleResponseTimeOverridesQueryStub {
    NSTimeInterval responseTime = 5.0;
    [app stubRequestsWithQueryParams:@[@"p=us", @"l"]
                returnJsonDictionary:@{@"request": @"stubbed"}
                          returnCode:200
                        responseTime:0.0];
    [app throttleRequestsWithQueryParams:@[@"p=us", @"l"] responseTime:responseTime];
    
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"exists == true"] evaluatedWithObject:app.alerts.element handler:nil];
    NSTimeInterval start = CFAbsoluteTimeGetCurrent();
    [app.buttons[@"https://us.yahoo.com/?p=us&l=1"] tap];
    [self waitForExpectationsWithTimeout:15.0 handler:nil];
    NSTimeInterval delta = ABS(CFAbsoluteTimeGetCurrent() - start);
    XCTAssertTrue(delta - responseTime > 0 && delta - responseTime < 2.0);
    
    XCTAssertTrue([[app.alerts[@"Result"] staticTexts][@"Stubbed"] exists]);
    [app.buttons[@"OK"] tap];
    
    [app throttleRequestRemoveAll];
}

- (void)testCustomCommand {
    NSString *rndString = [NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()];
    [app performCustomCommandNamed:@"myCustomCommand" object:rndString];
    
    NSString *rndStringRemote = [app userDefaultsObjectForKey:@"custom_command_test"];
    
    XCTAssertEqualObjects(rndString, rndStringRemote);
    
    [app performCustomCommandNamed:@"myCustomCommand" object:nil];
    
    XCTAssertNil([app userDefaultsObjectForKey:@"custom_command_test"]);
}

- (void)testAutocompleteEnabled {
    NSString *text = @"Snell's Law";
    XCUIElement *tf = app.textFields[@"textfield"];
    [tf tap];
    [tf typeText:text];
    
    NSString *tfText = tf.value;
    
    XCTAssert(![tfText isEqualToString:text]);
}

- (void)testAutocompleteDisabled {
    [app terminate];
    
    app = [[SBTUITunneledApplication alloc] init];
    [app launchTunnelWithOptions:@[SBTUITunneledApplicationLaunchOptionResetFilesystem, SBTUITunneledApplicationLaunchOptionInhibitCoreLocation, SBTUITunneledApplicationLaunchOptionDisableUITextFieldAutocomplete] startupBlock:nil];
    
    // wait for app to start
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"exists == true"] evaluatedWithObject:app.buttons[@"https://us.yahoo.com/?p=us&l=1"] handler:nil];
    [self waitForExpectationsWithTimeout:15.0 handler:nil];
    
    NSString *text = @"Snell's Law";
    XCUIElement *tf = app.textFields[@"textfield"];
    [tf tap];
    [tf typeText:text];
    
    NSString *tfText = tf.value;
    
    XCTAssert([tfText isEqualToString:text]);
}

- (void)testGenericReturnData {
    NSString *genericReturnData = @"Hello world!";
    
    [app stubRequestsWithRegex:@"(.*)bing(.*)" returnData:[genericReturnData dataUsingEncoding:NSUTF8StringEncoding] contentType:@"text/plain" returnCode:200 responseTime:0.0];
    
    [app.buttons[@"https://www.bing.com/?q=retdata"] tap];
    
    XCTAssert([app.staticTexts[@"Hello world!"] exists]);
}

#pragma mark - Helper Methods

- (void)afterTapping:(XCUIElement *)element assertAlertMessageEquals:(NSString *)message {
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"exists == true"] evaluatedWithObject:app.alerts.element handler:nil];
    [element tap];
    [self waitForExpectationsWithTimeout:15.0 handler:nil];
    XCTAssertTrue([[app.alerts[@"Result"] staticTexts][message] exists]);
    [app.buttons[@"OK"] tap];
}


@end
