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

**Call `takeOff()` at the very start of `application(_:didFinishLaunchingWithOptions:)` — the same place as for non-scene apps — even when your app uses `UIWindowSceneDelegate`.** Do **not** move it into `scene(_:willConnectTo:options:)`.

The reason is ordering. `takeOff()` blocks until the test runner's startup block has finished injecting its state (`UserDefaults`, keychain, stubs, filesystem reset). `didFinishLaunching` runs *before* any scene callback, and it is typically where apps read that state (feature toggles, session restore, SDK setup). If `takeOff()` is deferred to the scene, all of `didFinishLaunching` executes against **un-injected, stale state**, and the scene builds its UI from stale data too.

`takeOff()` waits in a tunnel-private run-loop mode that services only tunnel-owned startup work, not UIKit lifecycle callbacks. Placed in `didFinishLaunching`, the scene-app path completes the handshake before iOS delivers `scene(_:willConnectTo:options:)`, keeping the launch sequence strictly ordered:

```swift
import UIKit

#if DEBUG
import SBTUITestTunnelServer
#endif

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        #if DEBUG
        SBTUITestTunnelServer.takeOff()   // completes before any scene connects
        #endif

        // Read toggles / restore session / configure SDKs here — the
        // tunnel-injected state is guaranteed to be in place.
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = // ...
        window?.makeKeyAndVisible()
    }
}
```

`setUserInterfaceAnimationSpeed` can be called from the startup block before the first scene connects. Its main-thread update is deferred until normal launch processing resumes and is applied to the current or next key window, without allowing scene callbacks to run before state injection completes.

### Multi-window apps

Call `takeOff()` from `didFinishLaunching`, not from `scene(_:willConnectTo:options:)`. The handshake runs once — repeated `takeOff()` calls are no-ops — and completes before any scene connects, so every scene (including additional windows that connect later) reads the state injected at launch.

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
