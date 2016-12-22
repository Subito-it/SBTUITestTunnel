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

**🔥 If you’re using CocoaPods v1.0 and your UI Tests fail to start, you may need to add $(FRAMEWORK_SEARCH_PATHS) to your Runpath Search Paths in the Build Settings of the UI Test target!**

## Installation (Manual)

Add files in the *Server* and *Common* folder to your application's target, *Client* and *Common* to the UI test target.

## Setup

### Application target

On the application's target call SBTUITestTunnelServer's `takeOff` method on top of `application(_:didFinishLaunchingWithOptions:)`.

    import UIKit
    import SBTUITestTunnel

    @UIApplicationMain
    class AppDelegate: UIResponder, UIApplicationDelegate {
        var window: UIWindow?

        func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
            #if DEBUG
                SBTUITestTunnelServer.takeOff()
            #endif

            return true
        }
    }

### 🔥 DEBUG pre-processor macro

To avoid shipping test code in production each and every file of the framework is surrounded with an #if DEBUG statement. **Therefore you have to wrap the `takeOff` method around the DEBUG pre-processor macro** as shown in the code above or you'll end up getting the following linking error when trying to build your application:
```
Undefined symbols for architecture i386:
  "_OBJC_CLASS_$_SBTUITestTunnelServer", referenced from:
      type metadata accessor for __ObjC.SBTUITestTunnelServer in AppDelegate.o
ld: symbol(s) not found for architecture i386
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

**Also make sure that your target/build configuration defines the DEBUG pre-processor macro!**

### UI Testing target

On the testing target no setup is required. You don't even need to instantiate an `XCUIApplication`, the framework automatically adds an `app` property (`SBTUITunneledApplication`) ready to use.

## Usage

`SBTUITunneledApplication`'s headers are well commented making the library's functionality self explanatory. You can also checkout the UI test target in the example project which show basic usage of the library.


### Startup

At launch you can optionally provide some options and a startup block which will be executed synchronously with app's launch. This is the right place to prepare (inject files, modify NSUserDefaults, etc) the app's startup status.

#### Launch with no options

You launch your tests in a similar fashion as you're used to.

    import SBTUITestTunnel

    class MyTestClass: XCTestCase {xw
        override func setUp() {
            super.setUp()
            
            app.launchTunnel()
        }
        
        func testStuff() {
            // ... 
        }
    }

_Note how we don't need to instantiate the `app` property_ 

#### Launch with options and startupBlock

    app.launchTunnelWithOptions([SBTUITunneledApplicationLaunchOptionResetFilesystem]) {
        // do additional setup before the app launches
        // i.e. prepare stub request, start monitoring requests
    }

- `SBTUITunneledApplicationLaunchOptionResetFilesystem` will delete the entire app's sandbox filesystem
- `SBTUITunneledApplicationLaunchOptionDisableUITextFieldAutocomplete` disables UITextField's autocomplete functionality which can lead to unexpected results when typing text.

### SBTRequestMatch

The stubbing/monitoring/throttling methods of the library require a `SBTRequestMatch` object in order to determine whether they should react to a network request.

You can specify url, query (parameter in GET and DELETE, body in POST and PUT) and HTTP method using one of the several class methods available

    public class func URL(url: String) -> Self // any request matching the specified regex on the request URL
    public class func URL(url: String, query: String) -> Self // same as above additionally matching the query (params in GET and DELETE, body in POST and PUT)
    public class func URL(url: String, query: String, method: String) -> Self // same as above additionally matching the HTTP method
    public class func URL(url: String, method: String) -> Self // any request matching the specified regex on the request URL and HTTP method

    public class func query(query: String) -> Self // any request matching the specified regex on the query (params in GET and DELETE, body in POST and PUT)
    public class func query(query: String?, method: String) -> Self // same as above additionally matching the HTTP method

    public class func method(method: String) -> Self // any request matching the HTTP method


### Stubbing

To stub a network request you pass the appropriate `SBTRequestMatch` object

    let stubId = app.stubRequestsMatching:SBTRequestMatch(SBTRequestMatch.URL("google.com"), returnJsonDictionary: ["key": "value"], returnCode: 200, responseTime: SBTUITunnelStubsDownloadSpeed3G)

    // from here on network request containing 'apple' will return a JSON {"request" : "stubbed" }
    ...

    app.stubRequestsRemoveWithId(stubId) // To remove the stub either use the identifier

    app.stubRequestsRemoveAll() // or remove all active stubs


### NSUserDefaults

#### Set object

    app.userDefaultsSetObject("test_value", forKey: "test_key");

#### Get object

    let obj = app.userDefaultsObjectForKey("test_key")

#### Remove object

    app.userDefaultsRemoveObjectForKey("test_key")


### Upload / Download items

#### Upload

    let pathToFile = ... // path to file
    app.uploadItemAtPath(pathToFile, toPath: "test_file.txt", relativeTo: .DocumentDirectory)

#### Download

    let uploadData = app.downloadItemFromPath("test_file.txt", relativeTo: .DocumentDirectory)

### Network monitoring

This may come handy when you need to check that specific network requests are made. You pass an `SBTRequestMatch` like for stubbing methods.

    app.monitorRequestsMatching(SBTRequestMatch.URL("apple.com"))

    // Interact with UI. Once ready flush calls and get the list of requests

    let requests: [SBTMonitoredNetworkRequest] = app.monitoredRequestsFlushAll()

    for request in requests {
        let requestBody = request.request!.HTTPBody // HTTP Body in POST request?
        let responseJSON = request.responseJSON
        let requestTime = request.requestTime // How long did the request take?
    }

    app.monitorRequestRemoveAll()

### Throttling

The library allows to throttle network calls by specifying a response time, which can be a positive number of seconds or one of the predefined `SBTUITunnelStubsDownloadSpeed*`constants. You pass an `SBTRequestMatch` like for stubbing methods.

    let throttleId = app.throttleRequestsMatching(SBTRequestMatch.URL("apple.com"), responseTime:SBTUITunnelStubsDownloadSpeed3G) ?? ""

    app.throttleRequestRemoveWithId(throttleId)

### Custom defined blocks of code

You can easily add a custom block of code in the application target that can be conveniently invoked from the test target. An NSString identifies the block of code when registering and invoking it.

#### Application target

You register a block of code that will be invoked from the test target as follows:

    SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandKey") {
        injectedObject in
        // this block will be invoked from app.performCustomCommandNamed()

        return "Any object you want to pass back to test target"
    }

**Note** It is your responsibility to unregister the custom command when it is no longer needed. Failing to do so may end up with unexpected behaviours.

#### Test target

You invoke the custom command by using the same identifier used on registration, optionally passing an NSObject:

    let objReturnedByBlock = app.performCustomCommandNamed("myCustomCommand", object: someObjectToInject)
    
## [Workaround] UI Testing Failure - Failure getting snapshot Error Domain=XCTestManagerErrorDomain Code=9 "Error getting main window -25204

To workaround this issue, which seem to occur more frequently in apps with long startup, an additional step  is required during the setup of your tunnel

In your application target you call `SBTUITestTunnelServer.takeOffCompleted(false)` right after `takeOff` (which should be on topo of your `application(_:didFinishLaunchingWithOptions:)`)

    import UIKit
    import SBTUITestTunnel

    @UIApplicationMain
    class AppDelegate: UIResponder, UIApplicationDelegate {
        var window: UIWindow?

        func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
            #if DEBUG
                SBTUITestTunnelServer.takeOff()
                SBTUITestTunnelServer.takeOffCompleted(false)
            #endif

            return true
        }
    }

You then call `SBTUITestTunnelServer.takeOffCompleted(true)` once you're sure that all your startup tasks are completed and your primary view controller is up and running on screen.

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
