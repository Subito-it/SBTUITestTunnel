# 🎛️ Advanced Setup Guide

This guide covers advanced configuration scenarios for users who need fine-grained control over their `XCUIApplication` instance. Most users should start with the standard [Setup Guide](./Setup.md) first.

## When You Need Advanced Setup

Use this advanced configuration when you:

- Have a custom `XCUIApplication` subclass
- Need precise control over the application lifecycle
- Want to customize the tunnel client behavior
- Need to disable automatic swizzling for compatibility reasons

---

## 🔧 Disabling Automatic Integration

By default, SBTUITestTunnel automatically provides an `app` property and manages the `XCUIApplication` instance. To disable this behavior:

**Add to your UI Test target's Build Settings:**
```
DISABLE_UITUNNEL_SWIZZLING = 1
```

This prevents SBTUITestTunnel from:
- Creating an automatic `XCUIApplication` instance
- Adding the `app` property to your test cases
- Performing automatic method swizzling

---

## 🎯 Custom XCUIApplication Implementation

### Option 1: Fully Custom Application Class

Create your own `XCUIApplication` subclass with complete control:

```swift
import XCTest
import SBTUITestTunnelClient

class CustomApplication: XCUIApplication {
    
    // 🔧 Lazy initialization of the tunnel client
    lazy var tunnelClient: SBTUITestTunnelClient = {
        let client = SBTUITestTunnelClient(application: self)
        client.delegate = self
        return client
    }()
    
    // 🚀 Custom launch method
    func launchTunnel(withOptions options: [String] = []) {
        // Add any custom pre-launch logic here
        tunnelClient.launchTunnel(withOptions: options)
    }
    
    // 🛑 Custom termination
    override func terminate() {
        // Add any custom cleanup logic here
        tunnelClient.terminate()
    }
}

// MARK: - SBTUITestTunnelClientDelegate
extension CustomApplication: SBTUITestTunnelClientDelegate {
    
    func testTunnelClientIsReady(toLaunch sender: SBTUITestTunnelClient) {
        // 🎬 Called when the tunnel is ready - launch the app
        launch()
    }
    
    func testTunnelClient(_ sender: SBTUITestTunnelClient, didShutdownWithError error: Error?) {
        // 🔍 Handle any errors that occur during shutdown
        if let error = error {
            print("Tunnel shutdown error: \(error.localizedDescription)")
        }
        
        // 🛑 Terminate the XCUIApplication
        super.terminate()
    }
}
```

### Using Your Custom Application

```swift
import XCTest

class MyAdvancedTests: XCTestCase {
    
    // 📱 Create and retain your custom application instance
    let app = CustomApplication()
    
    override func setUp() {
        super.setUp()
        
        // 🚀 Use your custom launch method
        app.launchTunnel()
    }
    
    override func tearDown() {
        // 🧹 Clean up when tests complete
        app.terminate()
        super.tearDown()
    }
    
    func testWithCustomApp() {
        // 🧪 Your test code here
        app.buttons["My Button"].tap()
        
        // ✅ You have full access to SBTUITestTunnel features
        app.tunnelClient.stubRequests(
            matching: SBTRequestMatch.url("api.example.com"),
            response: SBTStubResponse(response: ["message": "success"])
        )
    }
}
```

---

### Option 2: Extending SBTUITunneledApplication

For a simpler approach, extend the provided `SBTUITunneledApplication` class:

```swift
import SBTUITestTunnelClient

class MyCustomApplication: SBTUITunneledApplication {
    
    // 🔧 Add your custom methods and properties
    var customProperty: String = "default"
    
    func customLaunchMethod() {
        // 🎛️ Add custom logic before launch
        customProperty = "configured"
        
        // 🚀 Use the inherited launchTunnel method
        launchTunnel()
    }
    
    func performCustomAction() {
        // 🎯 Add domain-specific testing methods
        buttons["Special Action"].tap()
        // Add assertions or additional logic
    }
}
```

### Using the Extended Application

```swift
class MyTests: XCTestCase {
    
    let app = MyCustomApplication()
    
    override func setUp() {
        super.setUp()
        app.customLaunchMethod()  // Use your custom launch
    }
    
    func testCustomBehavior() {
        app.performCustomAction()  // Use your custom methods
        XCTAssertEqual(app.customProperty, "configured")
    }
}
```

---

## 🔍 Understanding the Delegate Pattern

The `SBTUITestTunnelClientDelegate` provides hooks into the tunnel lifecycle:

### `testTunnelClientIsReady(toLaunch:)`
- **When**: Called when the tunnel connection is established
- **Purpose**: This is when you should call `launch()` on your `XCUIApplication`
- **Important**: The app won't start until you call `launch()`

### `testTunnelClient(_:didShutdownWithError:)`
- **When**: Called when the tunnel shuts down
- **Purpose**: Handle cleanup and call `terminate()` on your app
- **Error Handling**: Check for errors to diagnose connection issues

---

## ⚡ Key Differences from Standard Setup

| Aspect | Standard Setup | Advanced Setup |
|--------|---------------|----------------|
| **App Property** | ✅ Automatic | ❌ Manual creation required |
| **Swizzling** | ✅ Enabled | ❌ Disabled |
| **Control Level** | 🔒 Limited | 🎛️ Full control |
| **Complexity** | 🟢 Simple | 🟡 Moderate |
| **Use Cases** | 👥 Most projects | 🔧 Custom requirements |

---

## 🚨 Important Considerations

1. **Lifecycle Management**: You're responsible for properly managing the application lifecycle
2. **Error Handling**: Implement proper error handling in delegate methods
3. **Memory Management**: Ensure proper cleanup in `tearDown` methods
4. **Testing**: Thoroughly test your custom implementation

---

## ❓ When to Use Each Approach

### Use **Standard Setup** when:
- ✅ You're new to SBTUITestTunnel
- ✅ You don't need custom `XCUIApplication` behavior
- ✅ You want the simplest possible setup

### Use **Advanced Setup** when:
- 🎛️ You have existing `XCUIApplication` subclasses
- 🔧 You need to customize application launch behavior
- 🎯 You want fine-grained control over the testing process
- 🔍 You need to integrate with other testing frameworks

---

💡 **Pro Tip**: Start with the standard setup and migrate to advanced setup only when you have specific requirements that can't be met with the default configuration.