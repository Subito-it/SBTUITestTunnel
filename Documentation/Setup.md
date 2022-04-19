# Setup

## Application target

On the application's target call SBTUITestTunnelServer's `takeOff` method on top of `application(_:didFinishLaunchingWithOptions:)`.

**All references to SBTUITestTunnel are wrapped around `#if DEBUG` conditionals**

```swift
import UIKit

#if DEBUG 
    import SBTUITestTunnelServer
#endif

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
```

## UI Testing target

On the testing target no setup is required. Note how you even don't need to instantiate an `XCUIApplication`, as SBTUITestTunnel automatically adds a convenience `app` property (`SBTUITunneledApplication`) ready for use.

While no setup is required in your UI Test target to use this library it might be that you need fine grained control of the `XCUIApplication` instance. Please refer to the [alternative target setup](Setup_alternative_target) documentation for further details.



## Project

#### 🔥 IMPORTANT, PLEASE READ

To use the framework you're required to define `DEBUG=1` or `ENABLE_UITUNNEL=1` in your _Preprocessor Macros_ and `DEBUG` or `ENABLE_UITUNNEL` in the _Swift Active Compilation Conditions_ (`SWIFT_ACTIVE_COMPILATION_CONDITIONS`) build settings. 

**Without these build settings compilation will fail with a `Undefined symbol: _OBJC_CLASS_$_SBTUITestTunnelServer`.**

## Project advanced usage (CocoaPods)

In some advanced cases the tou may be running tests on a custom build configuration that is missing the `DEBUG` preprocessor macro.

In that case you'll need to add the `ENABLE_UITUNNEL` and `ENABLE_UITUNNEL_SWIZZLING` macros the tunnel targets build setting by modify your Podfile and adding the following `post_install` action:

```ruby
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            if config.name == 'QA' # the name of your build configuration
              config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['$(inherited)', 'ENABLE_UITUNNEL=1', 'ENABLE_UITUNNEL_SWIZZLING=1']
              config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = ['$(inherited)', 'ENABLE_UITUNNEL', 'ENABLE_UITUNNEL_SWIZZLING']
            end
        end
    end
end
```

**Note**: You can set `ENABLE_UITUNNEL_SWIZZLING=0` if you plan on disabling swizzling and having your own sub-class of `XCUIApplication` instead of the automatically provided one.