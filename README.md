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
* network calls monitoring

The library consists of two separated components which communicate with each other, one to be instantiate in the application and the other in the testing code. A web server inside the application is used to create the link between the two components allowing test code to send requests to the application.

## Requirements

Requires iOS 8.0 or higher.

## Installation (CocoaPods)

We strongly suggest to use [cocoapods](https://cocoapods.org) being the easiest way to embed the library inside your project.

Your Podfile should include the sub project `SBTUITestTunnel/Server` for the app target and `SBTUITestTunnel/Client` for the UI test target.

    target :APP_TARGET do
      pod 'SBTUITestTunnel/Server'
    end
    target :UITESTS_TARGET, :exclusive => true do
      pod 'SBTUITestTunnel/Client'
    end

## Installation (Manual)

Add files in the *Server* and *Common* folder to your application's target, *Client* and *Common* to the UI test target.

## Setup

### Application target

Call `[SBTUITestTunnelServer takeOff]` from the application's `main` function

    #import "SBTAppDelegate.h"

    #if DEBUG
        #import "SBTUITestTunnelServer.h"
    #endif

    int main(int argc, char *argv[])
    {
    #if DEBUG
        [SBTUITestTunnelServer takeOff];
    #endif

        @autoreleasepool {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([SBTAppDelegate class]));
        }
    }

**Note** The web server won't startup in production code however we strongly suggest to avoid shipping SBTUITestTunnel at all in your production code, like for example wrapping the code inside a preprocessor conditional `#if` clause as shown above.

### UI Testing target

Instead of using `XCUIApplication` use `SBTUITunneledApplication`.


## Usage

`SBTUITunneledApplication`'s headers are well commented making the library's functionality self explanatory. You can also checkout the UI test target in the example project which show basic usage of the library.


### Startup

At launch you can optionally provide some options and a startup block which will be executed before the applicationDidFinishLaunching will be called. This is the right place to prepare (inject files, modify NSUserDefaults, etc) the app's startup status.

**Launch with no options**

    SBTUITunneledApplication *app = [[SBTUITunneledApplication alloc] init];
    [app launch];

**Launch with options and startupBlock**

    SBTUITunneledApplication *app = [[SBTUITunneledApplication alloc] init];

    [app launchTunnelWithOptions:@[SBTUITunneledApplicationLaunchOptionResetFilesystem, SBTUITunneledApplicationLaunchOptionAuthorizeLocation]
                    startupBlock:^{
        [app setUserInterfaceAnimationsEnabled:NO];
        [app userDefaultsSetObject:@(YES) forKey:@"show_startup_warning"]
        ...
    }];

### Stubbing

There are several ways to stub network calls

**Regex**

    NSString *stubId = [app stubRequestsWithRegex:@"(.*)apple(.*)"
                             returnJsonDictionary:@{@"request": @"stubbed"}
                                       returnCode:200
                                     responseTime:SBTUITunnelStubsDownloadSpeed3G];
    // from here on network request containing 'apple' will return a JSON {"request" : "stubbed" }
    ...

    [app stubRequestsRemoveWithId:stubId]; // To remove the stub either use the identifier

    [app stubRequestsRemoveAll]; // or remove all active stubs

### NSUserDefaults

**Set object**

    [app userDefaultsSetObject:@"test_value" forKey:@"test_key"]);

**Get object**

    id obj = [app userDefaultsObjectForKey:@"test_key"]

**Remove object**

    [app userDefaultsRemoveObjectForKey:@"test_key"]

### Network monitoring

This may come handy when you need to check that specific network requests are made.

    [app monitorRequestsWithRegex:@"(.*)apple(.*)"];

    ...  
    // once ready flush calls and get the list of requests

    NSArray<SBTMonitoredNetworkRequest *> *requests = [app monitoredRequestsFlushAll];

    for (SBTMonitoredNetworkRequest *request in requests) {
        // do things with the recorded requests
    }

    [app monitorRequestRemoveAll];

### Upload / Download items

**Upload**

    NSString *testFilePath = ... // path to file
    [app uploadItemAtPath:testFilePath toPath:@"test_file.txt" relativeTo:NSDocumentDirectory];

**Download**

    NSData *uploadData = [app downloadItemFromPath:@"test_file.txt" relativeTo:NSDocumentDirectory];


## Thanks

Kudos to the developers of the following pods which we use in SBTUITestTunnel:

* [GCDWebServer](https://github.com/swisspol/GCDWebServer)
* [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs)
* [NSHash](https://github.com/jerolimov/NSHash)
* [FXKeychain](https://github.com/nicklockwood/FXKeychain)

## Contributions

Contributions are welcome! If you have a bug to report, feel free to help out by opening a new issue or sending a pull request.

## Authors

[Tomas Camin](https://github.com/tcamin) ([@tomascamin](https://twitter.com/tomascamin))

## License

SBTUITestTunnel is available under the Apache License, Version 2.0. See the LICENSE file for more info.
