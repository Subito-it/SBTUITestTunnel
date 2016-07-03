# SBTUITestTunnel

[![Version](https://img.shields.io/cocoapods/v/SBTUITestTunnel.svg?style=flat)](http://cocoadocs.org/docsets/SBTUITestTunnel)
[![License](https://img.shields.io/cocoapods/l/SBTUITestTunnel.svg?style=flat)](http://cocoadocs.org/docsets/SBTUITestTunnel)
[![Platform](https://img.shields.io/cocoapods/p/SBTUITestTunnel.svg?style=flat)](http://cocoadocs.org/docsets/SBTUITestTunnel)

## Overview

Apple introduced a new UI Testing feature starting from Xcode 7 that is, quoting Will Turner [on stage at the WWDC](https://developer.apple.com/videos/play/wwdc2015/406/), a huge expansion of the testing technology in the developer tools. The framework is easy to use and the integration with the IDE is great however there is a major problem with the way tests are launched. Testing code runs as a separate process which prevents to directly share data with the app under test making it hard to do things like dynamically inject data or stub network calls.

With SBTUITestTunnel we extended UI testing functionality allowing to dynamically:
* stub network calls
* interact with NSUserDefaults and Keychain
* download/upload files from/to the app's sandbox
* monitor network calls
* define custom blocks of codes executed in the application target

The library consists of two separated components which communicate with each other, one to be instantiate in the application and the other in the testing code. A web server inside the application is used to create the link between the two components allowing test code to send requests to the application.

## Requirements

Requires iOS 8.0 or higher.

## Installation (CocoaPods)

We strongly suggest to use [cocoapods](https://cocoapods.org) being the easiest way to embed the library inside your project.

Your Podfile should include the sub project `SBTUITestTunnel/Server` for the app target and `SBTUITestTunnel/Client` for the UI test target.

    target 'APP_TARGET' do
      pod 'SBTUITestTunnel/Server'
    end
    target 'UITESTS_TARGET' do
      pod 'SBTUITestTunnel/Client'
    end

## Installation (Manual)

Add files in the *Server* and *Common* folder to your application's target, *Client* and *Common* to the UI test target.

## Setup

### Application target

On the application's target call SBTUITestTunnelServer's `takeOff` method inside the application's delegate `initialize` class method.

**Objective-C**

    #import "SBTAppDelegate.h"
    #import "SBTUITestTunnelServer.h"

    @implementation SBTAppDelegate

    + (void)initialize {
        [super initialize];
        [SBTUITestTunnelServer takeOff];
    }

    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
        return YES;
    }

    @end

**Swift**

    import UIKit
    import SBTUITestTunnel

    @UIApplicationMain
    class AppDelegate: UIResponder, UIApplicationDelegate {
        var window: UIWindow?

        override class func initialize() {
            SBTUITestTunnelServer.takeOff()
            super.initialize()
        }

        func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
            return true
        }
    }

**Note** Each and every file of the framework is wrapped around #if DEBUG pre-processor directive to avoid that any of its code accidentally ends in production when releasing. Check your pre-processor macros verifying that DEBUG is not defined in your release code!

### UI Testing target

Instead of using `XCUIApplication` use `SBTUITunneledApplication`.


## Usage

`SBTUITunneledApplication`'s headers are well commented making the library's functionality self explanatory. You can also checkout the UI test target in the example project which show basic usage of the library.


### Startup

At launch you can optionally provide some options and a startup block which will be executed before the `applicationDidFinishLaunching` will be called. This is the right place to prepare (inject files, modify NSUserDefaults, etc) the app's startup status.

#### Launch with no options

**Objective-C**

    SBTUITunneledApplication *app = [[SBTUITunneledApplication alloc] init];
    [app launch];

**Swift**

    let app = SBTUITunneledApplication()
    app.launch()


#### Launch with options and startupBlock

**Objective-C**

    SBTUITunneledApplication *app = [[SBTUITunneledApplication alloc] init];

    [app launchTunnelWithOptions:@[SBTUITunneledApplicationLaunchOptionResetFilesystem, SBTUITunneledApplicationLaunchOptionInhibitCoreLocation]
                    startupBlock:^{
        [app setUserInterfaceAnimationsEnabled:NO];
        [app userDefaultsSetObject:@(YES) forKey:@"show_startup_warning"]
        ...
    }];

**Swift**

    app = SBTUITunneledApplication()
    app.launchTunnelWithOptions([SBTUITunneledApplicationLaunchOptionResetFilesystem, SBTUITunneledApplicationLaunchOptionInhibitCoreLocation]) {
        // do additional setup before the app launches
        // i.e. prepare stub request, start monitoring requests
    }

- `SBTUITunneledApplicationLaunchOptionResetFilesystem` will delete the entire app's sandbox filesystem
- `SBTUITunneledApplicationLaunchOptionInhibitCoreLocation` will inhibit CoreLocation by conveniently swizzling some of it's startup methods. This is useful when you want to get rid from the initial authorization popups which may be tricky to handle otherwise.

### Stubbing

There are several ways to stub network calls

#### Regex

**Objective-C**

    NSString *stubId = [app stubRequestsWithRegex:@"(.*)apple(.*)"
                             returnJsonDictionary:@{@"request": @"stubbed"}
                                       returnCode:200
                                     responseTime:SBTUITunnelStubsDownloadSpeed3G];
    // from here on network request containing 'apple' will return a JSON {"request" : "stubbed" }
    ...

    [app stubRequestsRemoveWithId:stubId]; // To remove the stub either use the identifier

    [app stubRequestsRemoveAll]; // or remove all active stubs

**Swift**

    let stubId = app.stubRequestsWithRegex("(.*)apple(.*)", returnJsonDictionary: ["key": "value"], returnCode: 200, responseTime: SBTUITunnelStubsDownloadSpeed3G)

    // from here on network request containing 'apple' will return a JSON {"request" : "stubbed" }
    ...

    app.stubRequestsRemoveWithId(stubId) // To remove the stub either use the identifier

    app.stubRequestsRemoveAll() // or remove all active stubs


### NSUserDefaults

#### Set object

**Objective-C**

    [app userDefaultsSetObject:@"test_value" forKey:@"test_key"]);

**Swift**

    app.userDefaultsSetObject("test_value", forKey: "test_key");

#### Get object

**Objective-C**

    id obj = [app userDefaultsObjectForKey:@"test_key"]

**Swift**

    let obj = app.userDefaultsObjectForKey("test_key")

#### Remove object

**Objective-C**

    [app userDefaultsRemoveObjectForKey:@"test_key"]

**Swift**

    app.userDefaultsRemoveObjectForKey("test_key")


### Upload / Download items

#### Upload

**Objective-C**

    NSString *testFilePath = ... // path to file
    [app uploadItemAtPath:testFilePath toPath:@"test_file.txt" relativeTo:NSDocumentDirectory];

**Swift**

    let pathToFile = ... // path to file
    app.uploadItemAtPath(pathToFile, toPath: "test_file.txt", relativeTo: .DocumentDirectory)

#### Download

**Objective-C**

    NSData *uploadData = [app downloadItemFromPath:@"test_file.txt" relativeTo:NSDocumentDirectory];

**Swift**

    let uploadData = app.downloadItemFromPath("test_file.txt", relativeTo: .DocumentDirectory)

### Network monitoring

This may come handy when you need to check that specific network requests are made.

**Objective-C**

    [app monitorRequestsWithRegex:@"(.*)apple(.*)"];

    // Interact with UI. Once ready flush calls and get the list of requests

    NSArray<SBTMonitoredNetworkRequest *> *requests = [app monitoredRequestsFlushAll];

    for (SBTMonitoredNetworkRequest *request in requests) {
        NSData *requestBody = request.request.HTTPBody; // HTTP Body in POST request?
        NSDictionary *responseJSON = request.responseJSON;
        NSTimeInterval requestTime = request.requestTime; // How long did the request take?
    }

    [app monitorRequestRemoveAll];

**Swift**

    app.monitorRequestsWithRegex("(.*)myserver(.*)")

    // Interact with UI. Once ready flush calls and get the list of requests

    let requests: [SBTMonitoredNetworkRequest] = app.monitoredRequestsFlushAll()

    for request in requests {
        let requestBody = request.request!.HTTPBody // HTTP Body in POST request?
        let responseJSON = request.responseJSON
        let requestTime = request.requestTime // How long did the request take?
    }

    app.monitorRequestRemoveAll()

### Custom defined blocks of code

You can easily add a custom block of code in the application target that can be conveniently invoked from the test target. An NSString identifies the block of code when registering and invoking it.

#### Application target

You register a block of code that will be invoked from the test target as follows:

**Objective-C**

    [SBTUITestTunnelServer registerCustomCommandNamed:@"myCustomCommand" block:^(NSObject *object) {
        // the block of code that will be executed when the test target calls
        // [SBTUITunneledApplication performCustomCommandNamed:object:];
    }];

**Swift**

    SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandKey") {
        injectedObject in
        // this block will be invoked from app.performCustomCommandNamed()
    }

**Note** It is your responsibility to unregister the custom command when it is no longer needed. Failing to do so may end up with unexpected behaviours.

#### Test target

You invoke the custom command by using the same identifier used on registration, optionally passing an NSObject:

**Objective-C**

    [app performCustomCommandNamed:@"myCustomCommand" object:someObject];

**Swift**

    app.performCustomCommandNamed("myCustomCommand", object: someObjectToInject)

## Thanks

Kudos to the developers of the following pods which we use in SBTUITestTunnel:

* [GCDWebServer](https://github.com/swisspol/GCDWebServer)
* [FXKeychain](https://github.com/nicklockwood/FXKeychain)

## Contributions

Contributions are welcome! If you have a bug to report, feel free to help out by opening a new issue or sending a pull request.

## Authors

[Tomas Camin](https://github.com/tcamin) ([@tomascamin](https://twitter.com/tomascamin))

## License

SBTUITestTunnel is available under the Apache License, Version 2.0. See the LICENSE file for more info.
