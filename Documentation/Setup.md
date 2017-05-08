# Setup

## Application target

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

## 🔥 Preprocessor macros  

To use the framework you're required to define `DEBUG=1` or `ENABLE_UITUNNEL=1` in your preprocessor macros build settings. This is needed to make sure that test code doesn't end by mistake in production. Make sure that these macros should be defined in both your application target and Pods project.

### Basic usage

Nothing particular needs to be done if you'll be running your test code with a build configuration that already defines `DEBUG=1` and remember to **wrap all calls to the framework around `#if DEBUG`s** as shown in the example above or you may end up getting linking errors that might look something like:
```
Undefined symbols for architecture i386:
  "_OBJC_CLASS_$_SBTUITestTunnelServer", referenced from:
      type metadata accessor for __ObjC.SBTUITestTunnelServer in AppDelegate.o
ld: symbol(s) not found for architecture i386
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

### Advanced usage

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


## UI Testing target

On the testing target no setup is required. You don't even need to instantiate an `XCUIApplication`, the framework automatically adds an `app` property (`SBTUITunneledApplication`) ready to use.

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