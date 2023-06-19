# Setup

## 🔥 IMPORTANT, PLEASE READ

The testing library contains code that should not be shipped to production. It is your responsibility to ensure that this library and its dependencies (GCDWebServer) are excluded from the build you send to the AppStore.

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


## Tunneling mode

The library allows tunneling via HTTP or via IPC (default). You can force disabling IPC by setting a `SBTUITestTunnelDisableIPC=NO` key in the Info.plist of the UITesting target.
