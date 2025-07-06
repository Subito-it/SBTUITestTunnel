# 🔧 Usage Guide

SBTUITestTunnel provides powerful capabilities to enhance your iOS UI testing. This comprehensive guide covers all the features and shows you how to use them effectively.

## 📋 Table of Contents

- [🚀 Launching Tests](#-launching-tests)
- [🌐 Network Features](#-network-features)
  - [🎯 Request Matching](#-request-matching)
  - [🔄 Stubbing Requests](#-stubbing-requests)
  - [📊 Network Monitoring](#-network-monitoring)
  - [⏱️ Throttling](#-throttling)
  - [🍪 Block Cookies](#-block-cookies)
  - [✏️ Request Rewriting](#-request-rewriting)
- [🔌 WebSockets](#-websockets)
- [⚙️ User Defaults Access](#-user-defaults-access)
- [📝 Custom Code Execution](#-custom-code-execution)
- [📱 Advanced Scrolling](#-advanced-scrolling)
- [📍 Core Location Stubbing](#-core-location-stubbing)
- [🔔 User Notifications Stubbing](#-user-notifications-stubbing)
- [🌐 WKWebView Stubbing](#-wkwebview-stubbing)

---

## 🚀 Launching Tests

Replace the standard `launch()` method with SBTUITestTunnel's enhanced launch methods to establish the testing tunnel.

### Basic Launch

```swift
import SBTUITestTunnelClient

class YourTestClass: XCTestCase {
    override func setUp() {
        super.setUp()
        app.launchTunnel()
    }
    
    func testSomething() {
        // Your test code here
    }
}
```

> 💡 **Note**: The `app` property is automatically provided - no need to instantiate `XCUIApplication`!

### Launch with Options

Customize the launch behavior with these options:

| Option | Description |
|--------|-------------|
| `SBTUITunneledApplicationLaunchOptionResetFilesystem` | 🗑️ Clears the entire app sandbox |
| `SBTUITunneledApplicationLaunchOptionDisableUITextFieldAutocomplete` | ⌨️ Disables autocomplete to prevent unpredictable text input |

```swift
app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem]) {
    // 🔧 Pre-launch setup: configure stubs, start monitoring, etc.
    app.stubRequests(matching: SBTRequestMatch.url("api.example.com"), 
                    response: SBTStubResponse(response: ["status": "success"]))
}
```

---

## 🌐 Network Features

### 🎯 Request Matching

The `SBTRequestMatch` class is the foundation for all network operations. It determines which requests to target using **regular expressions** for URL patterns, query parameters, headers, and body content.

> ⚠️ **Important**: All matching parameters in `SBTRequestMatch` use **regular expressions**, not literal string matching. A **partial match** is sufficient - the regex doesn't need to match the entire string.

#### URL Matching Examples

For a request to `http://api.example.com/v1/user/12345/profile?lang=en&theme=dark`:

```swift
// ✅ Match the base path (ignoring query parameters)
let match1 = SBTRequestMatch.url("api.example.com/v1/user/12345/profile")

// ✅ Match any user ID with wildcards
let match2 = SBTRequestMatch.url("api.example.com/v1/user/.*/profile")

// ✅ Match with specific query parameters
let match3 = SBTRequestMatch.url("api.example.com/v1/user/.*/profile\\?.*lang=en")
```

#### Advanced Query Matching

```swift
// ✅ Match requests with specific query parameters (order-independent)
let match = SBTRequestMatch.url("api.example.com/v1/user/.*/profile", 
                                query: ["&lang=en", "&theme=dark"])

// ✅ Use negation with ! prefix
let match = SBTRequestMatch.url("api.example.com/v1/user/.*/profile", 
                                query: ["&lang=en", "!debug=true"])
```

#### Body and Header Matching

```swift
// 📝 Match POST requests with specific body content
let postMatch = SBTRequestMatch(url: "api.example.com", 
                                query: [], 
                                method: "POST", 
                                body: "userId.*12345")

// 📋 Match based on request headers
let headerMatch = SBTRequestMatch(url: "api.example.com", 
                                  requestHeaders: ["Accept": "application/json", 
                                                 "Authorization": "Bearer.*"])
```

### 🔄 Stubbing Requests

Create custom responses for network requests to test different scenarios without relying on external services.

#### Basic Stubbing

```swift
let match = SBTRequestMatch.url("api.example.com/user/profile")
let response = SBTStubResponse(response: ["name": "John Doe", "email": "john@example.com"])

let stubId = app.stubRequests(matching: match, response: response)

// 🗑️ Remove stub when done
app.stubRequestsRemove(id: stubId)
```

#### Advanced Response Configuration

```swift
let response = SBTStubResponse(
    response: ["error": "User not found"],
    headers: ["Content-Type": "application/json"],
    contentType: "application/json",
    returnCode: 404,
    responseTime: 2.0,        // 2-second delay
    activeIterations: 3       // Only handle first 3 requests
)
```

#### Error Simulation

```swift
// 🚫 Simulate network failures
let errorResponse = SBTStubFailureResponse(errorCode: URLError.notConnectedToInternet.rawValue)
app.stubRequests(matching: match, response: errorResponse)
```

#### Multiple Stubs (LIFO Order)

```swift
// 🔄 Test authentication flow: fail first, succeed after retry
app.stubRequests(matching: authMatch, response: successResponse)
app.stubRequests(matching: authMatch, response: authErrorResponse(activeIterations: 1))

// First request will get auth error, subsequent requests will succeed
```

### 📊 Network Monitoring

Track network requests to verify your app's behavior.

```swift
// 👀 Start monitoring
app.monitorRequests(matching: SBTRequestMatch.url("api.example.com"))

// 🎭 Perform UI actions that trigger network requests
app.buttons["Load Data"].tap()

// 📊 Analyze captured requests
let requests: [SBTMonitoredNetworkRequest] = app.monitoredRequestsFlushAll()

for request in requests {
    let requestBody = request.request?.httpBody
    let responseJSON = request.responseJSON
    let requestTime = request.requestTime    // Performance analysis
    
    print("Request took \(requestTime) seconds")
}

// 🧹 Clean up
app.monitorRequestRemoveAll()
```

### ⏱️ Throttling

Simulate different network conditions to test your app's performance under various scenarios.

```swift
// 🐌 Simulate 3G speed
let throttleId = app.throttleRequests(
    matching: SBTRequestMatch.url("api.example.com"), 
    responseTime: SBTUITunnelStubsDownloadSpeed3G
)

// 🏃‍♂️ Available speed constants:
// - SBTUITunnelStubsDownloadSpeedGPRS
// - SBTUITunnelStubsDownloadSpeedEDGE  
// - SBTUITunnelStubsDownloadSpeed3G
// - SBTUITunnelStubsDownloadSpeedWifi

// 🗑️ Remove throttling
app.throttleRequestRemove(withId: throttleId)
```

### 🍪 Block Cookies

Prevent cookies from being sent with specific requests.

```swift
let cookieBlockId = app.blockCookiesInRequests(matching: SBTRequestMatch.url("analytics.example.com"))

// 🧹 Remove cookie blocking
app.blockCookiesRequestsRemove(withId: cookieBlockId)
```

### ✏️ Request Rewriting

Modify requests and responses on-the-fly to test edge cases.

```swift
// 🔄 Replace API endpoints for testing
let rewrite = SBTRewrite(
    urlReplacement: [SBTRewriteReplacement(find: "prod-api", replace: "staging-api")],
    requestBodyReplacement: [SBTRewriteReplacement(find: "version=1.0", replace: "version=2.0")]
)

app.rewriteRequests(matching: SBTRequestMatch.url("api.example.com"), with: rewrite)
```

---

## 🔌 WebSockets

Test real-time features by interacting with WebSocket connections.

```swift
// 📤 Send messages
app.webSocketSend(message: "Hello from test!")

// 📥 Receive messages  
let message = app.webSocketReceiveMessage()

// 🔍 Get connected sockets
let sockets = app.webSocketConnectedSockets()

// 🎯 Target specific WebSocket by UUID
app.webSocketSend(message: "Targeted message", toWebSocketWithUUID: socketUUID)
```

---

## ⚙️ User Defaults Access

Directly manipulate app preferences during testing.

```swift
// 💾 Set values
app.userDefaultsSetObject("premium_user" as NSCoding, forKey: "user_type")
app.userDefaultsSetObject(true as NSCoding, forKey: "onboarding_completed")

// 📖 Read values
let userType = app.userDefaultsObject(forKey: "user_type") as? String
XCTAssertEqual(userType, "premium_user")

// 🗑️ Remove values
app.userDefaultsRemoveObject(forKey: "temporary_data")
```

---

## 📝 Custom Code Execution

Execute arbitrary code within your app's context for advanced testing scenarios.

### App Target Registration

```swift
// 📱 In your app target
SBTUITestTunnelServer.registerCustomCommandNamed("fetchUserData") { injectedObject in
    // 🔧 Custom logic here
    let userId = injectedObject as? String ?? "defaultUser"
    let userData = UserService.fetchUserData(for: userId)
    return userData
}

// ⚠️ Remember to unregister when done
SBTUITestTunnelServer.unregisterCommandNamed("fetchUserData")
```

### Test Target Execution

```swift
// 🧪 In your test target  
let userData = app.performCustomCommandNamed("fetchUserData", object: "user123")
XCTAssertNotNil(userData)
```

---

## 📱 Advanced Scrolling

Perform precise scrolling operations on collection views, table views, and scroll views.

> ⚠️ **SwiftUI Important**: Always interact with the XCUIElement before using scroll APIs:
> ```swift
> XCTAssert(app.collectionViews["details"].exists) // ← Required!
> app.scrollCollectionView(withIdentifier: "details", toElementIndex: 5, animated: true)
> ```

### 📋 Table Views

```swift
// 📍 Scroll to specific row
app.scrollTableView(withIdentifier: "userList", toRow: 10, animated: true)

// 🎯 Scroll to element by identifier
app.scrollTableView(withIdentifier: "userList", 
                   toElementWithIdentifier: "user_john_doe", 
                   animated: true)

// 📜 Scroll to bottom
app.scrollTableView(withIdentifier: "userList", toRow: .max, animated: false)
```

### 🔲 Collection Views

```swift
// 📍 Scroll to specific item
app.scrollCollectionView(withIdentifier: "photoGrid", toRow: 25, animated: true)

// 🎯 Scroll to element by identifier  
app.scrollCollectionView(withIdentifier: "photoGrid",
                        toElementWithIdentifier: "photo_sunset",
                        animated: true)
```

### 📜 Scroll Views

```swift
// 🎯 Scroll to specific element
app.scrollScrollViewWithIdentifier(withIdentifier: "contentScroll",
                                  toElementWitIdentifier: "section_footer",
                                  animated: true)

// 📏 Scroll to normalized offset (0.0 - 1.0)
app.scrollScrollViewWithIdentifier(withIdentifier: "contentScroll",
                                  toOffset: 0.75,  // 75% down
                                  animated: true)
```

---

## 📍 Core Location Stubbing

Test location-based features without requiring actual GPS data.

```swift
// 🔧 Enable location stubbing
app.coreLocationStubEnabled(true)

// 📍 Set custom location
let location = CLLocation(latitude: 37.7749, longitude: -122.4194) // San Francisco
app.coreLocationStubManagerLocation(location)

// 🔐 Test different authorization states
app.coreLocationStubAuthorizationStatus(.denied)
app.coreLocationStubAuthorizationStatus(.authorizedWhenInUse)

// 📡 Control location services availability
app.coreLocationStubLocationServicesEnabled(false)

// 📢 Trigger location updates
let locations = [location]
app.coreLocationNotifyLocationUpdate(locations)

// ❌ Simulate location errors
app.coreLocationNotifyLocationError(locationError)
```

---

## 🔔 User Notifications Stubbing

Test notification permissions and handling without user interaction.

```swift
// 🔧 Enable notification stubbing
app.notificationCenterStubEnabled(true)

// 🔐 Test different authorization states
app.notificationCenterStubAuthorizationStatus(.denied)
app.notificationCenterStubAuthorizationStatus(.authorized)
app.notificationCenterStubAuthorizationStatus(.provisional)
```

---

## 🌐 WKWebView Stubbing

Enable network interception for WKWebView content.

```swift
// ⚠️ Enable WKWebView stubbing (affects POST request bodies)
app.wkWebViewStubEnabled(true)

// 🔄 Now you can stub requests from web views
let webMatch = SBTRequestMatch.url("api.website.com")
let webResponse = SBTStubResponse(response: ["web_data": "mocked"])
app.stubRequests(matching: webMatch, response: webResponse)
```

> ⚠️ **Important**: Enabling WKWebView stubbing strips POST request bodies due to internal API usage.

---

## 🎯 Pro Tips

- **🔍 Use descriptive identifiers** for stubs and monitoring to make debugging easier
- **🧹 Always clean up** stubs and monitors after tests to avoid interference
- **📊 Combine features** - use monitoring with stubbing to verify request counts
- **⏱️ Test performance** with throttling to ensure good user experience on slower networks
- **🔄 Test error scenarios** extensively using stub failures and custom responses

---

## 🔗 Additional Resources

- **[📱 Example Project](./Example.md)** - See all features in action
- **[⚙️ Setup Guide](./Setup.md)** - Configuration and troubleshooting
- **[🎛️ Advanced Setup](./Setup_alternative_target.md)** - Custom XCUIApplication usage

> 💡 The library's headers are well-documented, making exploration straightforward. Check out the UI test target in the example project for practical usage examples.
