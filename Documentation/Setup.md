# ⚙️ Setup Guide

This guide walks you through configuring SBTUITestTunnel in your project. Proper setup ensures the library works effectively while keeping your production builds secure.

## 🚨 Critical Security Notice

**SBTUITestTunnel contains testing code that must NOT be shipped to production.** 

It's your responsibility to ensure this library are excluded from App Store builds. The setup instructions below show how to use `#if DEBUG` conditionals to achieve this safely.

---

## 📱 Application Target Setup

Initialize the SBTUITestTunnel server in your app's `AppDelegate` when launching in debug mode.

```swift
import UIKit

#if DEBUG
import SBTUITestTunnelServer
#endif

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #if DEBUG
        SBTUITestTunnelServer.takeOff()
        #endif
        
        // Your app initialization code here...
        return true
    }
}
```

### For Objective-C Projects

```objc
#if DEBUG
#import "SBTUITestTunnelServer.h"
#endif

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
#if DEBUG
    [SBTUITestTunnelServer takeOff];
#endif
    
    // Your app initialization code here...
    return YES;
}

@end
```

---

## 📱 SceneDelegate Lifecycle Setup

For apps using `UIWindowSceneDelegate`, call `takeOff()` in `scene(_:willConnectTo:options:)` **before** creating the window and root view controller.

**Do not call `takeOff()` in the AppDelegate when using scenes.** `takeOff()` spins the main RunLoop while waiting for the test runner. This causes iOS to deliver `scene(_:willConnectTo:options:)` *during* the `takeOff()` call — before the startup block has executed. Placing `takeOff()` inside the scene callback avoids this, since the RunLoop spin cannot re-enter the same scene connection.

```swift
import UIKit

#if DEBUG
import SBTUITestTunnelServer
#endif

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        #if DEBUG
        SBTUITestTunnelServer.takeOff()
        #endif
        
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = // ...
        window?.makeKeyAndVisible()
    }
}
```

---

## 🧪 UI Test Target Setup

**No additional setup required!** SBTUITestTunnel automatically provides a convenient `app` property (of type `SBTUITunneledApplication`) that's ready to use in your test cases.

```swift
import XCTest
import SBTUITestTunnelClient

class YourUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // The 'app' property is automatically available
        app.launchTunnel()
    }
    
    func testExample() {
        // Your test code using the 'app' property
    }
}
```

### Need More Control?

If you require fine-grained control over the `XCUIApplication` instance, check out our [Advanced Setup Guide](./Advanced_Setup.md) for custom configuration options.

---

## 🔧 Communication Modes

SBTUITestTunnel supports two communication methods between your tests and the app:

### IPC Mode (Default)
- **Faster** and more reliable
- Uses Inter-Process Communication
- **Recommended** for most use cases

### HTTP Mode
- Uses network communication
- Useful for specific testing scenarios
- Enable by adding `SBTUITestTunnelDisableIPC` = `YES` to your UI test target's `Info.plist`

---

## ✅ Verification

After setup, verify everything works by running a simple test:

```swift
func testSetupVerification() {
    app.launchTunnel()
    XCTAssertTrue(app.isRunning)
}
```

If the test passes, you're ready to explore SBTUITestTunnel's powerful features! 🎉
