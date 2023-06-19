# Setup

## Alternative UI Testing target integration

While no setup is required in your UI Test target to use this library it might be that you need fine grained control of the `XCUIApplication` instance. 

In this case adding `DISABLE_UITUNNEL_SWIZZLING=1` in your application target build settings will prevent this library from instantiating an instance of `XCUIApplication` and it won't add an `app` property on your `TestCase` classes.

This is useful if you have your own sub-class of `XCUIApplication` that you wish to use instead of the automatically provided one.

You'll need to create and retain an instance of `SBTUITestTunnelClient` and hook it up with your own `XCUIApplication` sub-class to be able to manage the tunnel client.

### Fully custom XCUIApplicaion example 

```swift
class MyCustomApplication: XCUIApplication {
    lazy var client: SBTUITestTunnelClient = {
        let client = SBTUITestTunnelClient(application: self)
        client.delegate = self
        return client
    }()
    
    func launchTunnel() {
        // Do any custom launch things
        client.launchTunnel()
    }
    
    override func terminate() {
        // Do any custom tidy up things
        client.terminate()
    }
}

extension MyCustomApplication: SBTUITestTunnelClientDelegate {
    func testTunnelClientIsReady(toLaunch sender: SBTUITestTunnelClient) {
        // Call the XCUIApplication.lanuch() method
        launch()
    }
    
    func testTunnelClient(_ sender: SBTUITestTunnelClient, didShutdownWithError error: Error?) {
        // optionally handle errors
        print(String(describing: error?.localizedDescription))
        
        // Call the XCUIApplication.terminate() method
        super.terminate()
    }
}

// Example useage in XCTestCase
class MyTests: XCTestCase {

    let app = MyCustomApplication()

    override func setUp() {
        super.setUp()

        // Call our custom launchApp() method
        app.launchApp()
    }

    func testSomething() {...}
}
```

The purpose of `SBTUITestTunnelClientDelegate` is to allow the tunnel to prepare before you launch the app and terminate before you terminate the app. Once the tunnel is setup `testTunnelClientIsReady(toLaunch:)` will be called and you should launch the app by calling `launch()`. 

If the tunnel fails to connect for any reason `testTunnelClient(_:didShutdownWithError:)` will be called with a provided `Error` instance. You can then decide whether to terminate the app, fail the test or just fail silently.

To terminate the app yourself you should call `terminate()` on the client instance, this allows the tunnel time to disconnect before the `testTunnelClient(_:didShutdownWithError:)` will be called, though unlike above `Error` will be nil. You can then call `terminate()` on the XCUIApplication instance you're retaining.

#### Part custom XCUIApplicaion Example 

As a convenience you can also sub-class `SBTUITunneledApplication` instead of `XCUIApplication` to get a default implementation that creates the `SBTUITestTunnelClient` and implements the delegate for you with default behaviour:

```swift
class MyCustomApplication: SBTUITunneledApplication {
    // Create other custom methods as needed
}

    
class MyTests: XCTestCase {
    
    let app = MyCustomApplication()
    
    override func setUp() {
        super.setUp()
    
        // Call launchTunnel() instead of launch()
        app.launchTunnel()
    }
    
    func testSomething() {...}
}
```

This main difference between sub-classing `SBTUITunneledApplication` and using the `automatic` setup approach is that no swizzling is used and you can use your own `XCUIApplication` sub-class. You still need to create and retain an `XCUIApplication` instance in your `XCTestCase` classes.