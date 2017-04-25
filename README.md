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

## Should I use this?

SBTUITestTunnel is intended to extend Apple's XCTest framework, not to replace it. It all boils down to a subclass of XCUIApplication which comes with additional features, so it is very easy to integrate (or at least try it out 😉) with your existing testing code.

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

### 🔥 Preprocessor macros  

To use the framework you're required to define `DEBUG=1` or `ENABLE_UITUNNEL=1` in your preprocessor macros build settings. This is needed to make sure that test code doesn't end by mistake in production. Make sure that these macros should be defined in both your application target and Pods project.

#### Basic usage

Nothing particular needs to be done if you'll be running your test code with a build configuration that already defines `DEBUG=1`. This is the case of the default debug build configuration which is the one used in most cases when running test. Just make sure to **wrap all calls to the framework around `#if DEBUG`s** as shown in the example above or you may end up getting linking errors that might look something like:
```
Undefined symbols for architecture i386:
  "_OBJC_CLASS_$_SBTUITestTunnelServer", referenced from:
      type metadata accessor for __ObjC.SBTUITestTunnelServer in AppDelegate.o
ld: symbol(s) not found for architecture i386
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

#### Advanced usage

In some advanced cases the `DEBUG=1` may not be defined in your application's target or Pods project. This can happen when using some customly named build_configurations (ie QA) where Cocoapods doesn't automatically set the `DEBUG` preprocessors for you.

<img src="https://raw.githubusercontent.com/Subito-it/SBTUITestTunnel/master/Images/qa_preprocessor_macros.png" width="460" />

In that case you'll need to add `ENABLE_UITUNNEL=1` in your application target build setting as shown above and modify your Podfile by adding the following `post_install` action (and re running `pod install`):

    post_install do |installer|
        installer.pods_project.targets.each do |target|
            target.build_configurations.each do |config|
                if config.name == 'QA' # the name of your build configuration
                    config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'ENABLE_UITUNNEL=1']
                end
            end
        end
    end


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

    app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem]) {
         // do additional setup before the app launches
         // i.e. prepare stub request, start monitoring requests
    }

- `SBTUITunneledApplicationLaunchOptionResetFilesystem` will delete the entire app's sandbox filesystem
- `SBTUITunneledApplicationLaunchOptionDisableUITextFieldAutocomplete` disables UITextField's autocomplete functionality which can lead to unexpected results when typing text.

### SBTRequestMatch

The stubbing/monitoring/throttling methods of the library require a `SBTRequestMatch` object in order to determine whether they should react to a network request.

You can specify a regex on the URL, multiple regex on the query (in `POST` and `PUT` requests they will match against the body) and HTTP method using one of the several class methods available.

#### Query parameter

The `query` parameter found in different `SBTRequestMatch` initializers is an array of regex strings that are checked with the request [query](https://tools.ietf.org/html/rfc3986#section-3.4). If all regex in array match the request is stubbed/monitored/throttled.

In a kind of unconventional syntax you can prefix the regex with and exclamation mark `!` to specify that the request must not match that specific regex, see the following examples.

#### Examples

The regex in `GET` and `DELETE` requests will match the entire URL including query parameters.

Below some matches for a sample request like http://wwww.myhost.com/v1/user/281218/info?param1=val1&param2=val2 :

    // this will match the request independently of the query parameters
    let sr = SBTRequestMatch.url("myhost.com/v1/user/281218/info")
    // this will match the request independently of the query parameters for any user id
    let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info")
    // this will match the request containing query parameters
    let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info\?param1=val1&param2=val2")
    // this will match the request containing only param1 = val1 query
    let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info\?.*param1=val1")

**Given that parameter order isn't guaranteed** it is recommended to specify the `query` parameter in the `SBTRequestMatch`'s initializer. This is an array of regex that need to fulfill all for the request to match.

Considering the previous example the following `SBTRequestMatch` will match if the request contains `param1=val1` AND `param2=val2`.

    let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info", query: ["&param1=val1", "&param2=val2"])
    let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info", query: ["&param2=val2", "&param1=val1"])
    
You can additionally specify that the query should not contain something by prefixing the regex with an exclamantion mark `!`:

    let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info", query: ["&param1=val1", "&param2=val2", "!param3=val3"])

This will match if the query contains `param1=val1` AND `param2=val2` AND NOT `param3=val3`

Finally you can limit a specific HTTP method by specifying it in the `method` parameter.

    // will match GET request only
    let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info", query: ["&param1=val1", "&param2=val2"], method: "GET")
    let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info", method: "GET")


### Stubbing

To stub a network request you pass the appropriate `SBTRequestMatch` object

    let stubId = app.stubRequests(matching: SBTRequestMatch.url("google.com"), returnJsonDictionary: ["key": "value"], returnCode: 200, responseTime: SBTUITunnelStubsDownloadSpeed3G)

    // from here on network request containing 'apple' will return a JSON {"request" : "stubbed" }
    ...

    app.stubRequestsRemoveWithId(stubId) // To remove the stub either use the identifier

    app.stubRequestsRemoveAll() // or remove all active stubs


### NSUserDefaults

#### Set object

    app.userDefaultsSetObject("test_value" as NSCoding, forKey: "test_key");

#### Get object

    let obj = app.userDefaultsObject(forKey: "test_key")
    
#### Remove object

    app.userDefaultsRemoveObject(forKey: "test_key")


### Upload / Download items

#### Upload

    let pathToFile = ... // path to file
    app.uploadItem(atPath: pathToFile, toPath: "test_file.txt", relativeTo: .documentDirectory)

#### Download

    let uploadData = app.downloadItems(fromPath: "test_file.txt", relativeTo: .documentDirectory)

### Network monitoring

This may come handy when you need to check that specific network requests are made. You pass an `SBTRequestMatch` like for stubbing methods.

    app.monitorRequests(matching: SBTRequestMatch.url("apple.com"))
        
    // Interact with UI. Once ready flush calls and get the list of requests
        
    let requests: [SBTMonitoredNetworkRequest] = app.monitoredRequestsFlushAll()
        
    for request in requests {
        let requestBody  = request.request!.HTTPBody // HTTP Body in POST request?
        let responseJSON = request.responseJSON
        let requestTime  = request.requestTime // How long did the request take?
    }
        
    app.monitorRequestRemoveAll()

### Throttling

The library allows to throttle network calls by specifying a response time, which can be a positive number of seconds or one of the predefined `SBTUITunnelStubsDownloadSpeed*`constants. You pass an `SBTRequestMatch` like for stubbing methods.

    let throttleId = app.throttleRequests(matching: SBTRequestMatch.url("apple.com"), responseTime:SBTUITunnelStubsDownloadSpeed3G) ?? ""
        
     app.throttleRequestRemove(withId: throttleId)

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
    
## Workarounding _UI Testing Failure - Failure getting snapshot Error Domain=XCTestManagerErrorDomain Code=9 "Error getting main window -25204_

To workaround this issue, which seem to occur more frequently in apps with long startup, an additional step is required during the setup of the tunnel in the application target:

Call `SBTUITestTunnelServer.takeOffCompleted(false)` right after `takeOff` (which should be on topo of your `application(_:didFinishLaunchingWithOptions:)`)

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

🔥🔥🔥**You then HAVE TO call `SBTUITestTunnelServer.takeOffCompleted(true)` once you're sure that all your startup tasks are completed and your primary view controller is up and running on screen.**

This will guarantee that the tests will start executing once the view hierarchy of the app is ready.

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
