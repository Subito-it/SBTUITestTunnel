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

To use the framework you're required to define `DEBUG=1` or `ENABLE_UITUNNEL=1` in your preprocessor macros build settings.

If your integrating the framwork in a Swift project make sure that the _Acive Compilation Conditions_ (`SWIFT_ACTIVE_COMPILATION_CONDITIONS`) build settings contains `DEBUG` or `ENABLE_UITUNNEL` as well.

**This is needed to make sure that test code doesn't get mixed by mistake with production code. Make sure that these build settings are defined both in your application and Pods targets.**


## Project advanced usage (CocoaPods)

In some advanced cases the `DEBUG=1` may not (or can not) be defined in your application's target or Pods project. This can happen when using some customly named build_configurations (ie QA) where Cocoapods doesn't automatically set the `DEBUG` preprocessors for you.

<img src="https://raw.githubusercontent.com/Subito-it/SBTUITestTunnel/master/Images/qa_preprocessor_macros.png" width="460" />

In that case you'll need to add `ENABLE_UITUNNEL=1` in your application target build setting as shown above and modify your Podfile by adding the following `post_install` action (and re running `pod install`):

```ruby
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            if config.name == 'QA' # the name of your build configuration
                config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'ENABLE_UITUNNEL=1']
            end
        end
    end
end
```
