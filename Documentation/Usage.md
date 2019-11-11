# Usage

- [Launching tests](#launching-tests)
- [Networking features](#networking-features)
- [User defaults access](#user-defaults-access)
- [Custom code blocks](#custom-code-blocks)
- [Fine grain scrolling](#fine-grain-scrolling)
- [CLLocationManager stubbing](#cllocationmanager-stubbing)
- [UNUserNotificationCenter stubbing](#unusernotficationcenter-stubbing)
- [WKWebViews stubbing](#wkwebview-stubbing)

`SBTUITunneledApplication`'s headers are well commented making the library's functionality self explanatory. You can also checkout the UI test target in the example project which show basic usage of the library.

## Launching tests

Instead of calling the `launch()` method on `XCUIApplication` as you're used to use `launchTunnel()` or `launchTunnel(options:startupBlock:)`. These methods will launch the test and establish the tunnel connection.

### Launch with no options

```swift
import SBTUITestTunnelClient

class MyTestClass: XCTestCase {
    override func setUp() {
        super.setUp()
        
        app.launchTunnel()
    }
    
    func testStuff() {
        // ... 
    }
}
```    

_Note how we don't need to instantiate the `app` property_ 

### Launch with options and startupBlock

```swift
app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem]) {
    // do additional setup before the app launches
    // i.e. prepare stub request, start monitoring requests
}
```    

#### Options

- `SBTUITunneledApplicationLaunchOptionResetFilesystem` will delete the entire app's sandbox filesystem
- `SBTUITunneledApplicationLaunchOptionDisableUITextFieldAutocomplete` disables UITextField's autocomplete functionality which can lead to unexpected results when typing text.

#### StartupBlock

The startup block contains code that will be executed before the app enters the `applicationDidFinishLaunching(_:)`. This is the right place to setup the application before it gets launched

## Networking features

### SBTRequestMatch

The stubbing/monitoring/throttling and rewrite methods of the library require a `SBTRequestMatch` object in order to determine whether they should react to a certain network request.

You can specify a regex on the URL, multiple regex on the query (in `POST` and `PUT` requests they will match against the body) and HTTP method using one of the several class methods available.

#### Query parameter

The `query` parameter found in different `SBTRequestMatch` initializers is an array of regex strings that are checked with the request [query](https://tools.ietf.org/html/rfc3986#section-3.4). If all regex in array match the request is stubbed/monitored/throttled.

In a kind of unconventional syntax you can prefix the regex with an exclamation mark `!` to specify that the request must not match that specific regex, see the following examples.

#### Body parameter

The `body` parameter allows to match the request against its HTTP Body. As for the `query` parameter, the passed value is used as a regex which is evaluated on the request HTTP Body and the exlamation mark `!` can be used to specify an "inverted match" (i.e. that the HTTP Body should NOT match the provided `body` pattern).

#### Examples

The regex in `GET` and `DELETE` requests will match the entire URL including query parameters.

Below some matches for a sample request like http://wwww.myhost.com/v1/user/281218/info?param1=val1&param2=val2 :

```swift
// this will match the request independently of the query parameters
let sr = SBTRequestMatch.url("myhost.com/v1/user/281218/info")
// this will match the request independently of the query parameters for any user id
let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info")
// this will match the request containing query parameters
let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info\?param1=val1&param2=val2")
// this will match the request containing only param1 = val1 query
let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info\?.*param1=val1")
```

**Given that parameter order isn't guaranteed** it is recommended to specify the `query` parameter in the `SBTRequestMatch`'s initializer. This is an array of regex that need to fulfill all for the request to match.

Considering the previous example the following `SBTRequestMatch` will match if the request contains `param1=val1` AND `param2=val2`.

```swift
let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info", query: ["&param1=val1", "&param2=val2"])
let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info", query: ["&param2=val2", "&param1=val1"])
```    
    
You can additionally specify that the query should not contain something by prefixing the regex with an exclamantion mark `!`:

```swift
let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info", query: ["&param1=val1", "&param2=val2", "!param3=val3"])
```    

This will match if the query contains `param1=val1` AND `param2=val2` AND NOT `param3=val3`

The `body` parameter can be used to match HTTP Body and also supports `!` to specify "inverted matches":

```swift	
let sr = SBTRequestMatch(url: "myhost.com", query: [], method: "POST", body: "SomeBodyContent")
let sr = SBTRequestMatch(url: "myhost.com", query: [], method: "POST", body: "!UnwantedBodyContent")
```

Finally you can limit a specific HTTP method by specifying it in the `method` parameter.

```swift
// will match GET request only
let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info", query: ["&param1=val1", "&param2=val2"], method: "GET")
let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info", method: "GET")
```    

### Stubbing

To stub a network request you pass the appropriate `SBTRequestMatch` and `SBTStubResponse` objects

```swift
let stubId = app.stubRequests(matching: SBTRequestMatch.url("google.com"), response: SBTStubResponse(response: ["key": "value"])

// from here on network requests containing 'google.com' will return a JSON {"key" : "value" }
...

app.stubRequestsRemoveWithId(stubId) // To remove the stub either use the identifier

app.stubRequestsRemoveAll() // or remove all active stubs
```

A second stub initializer is available that automatically removes the stub after a certain number of times that the request is matched.

```swift
let stubId = app.stubRequests(matching: SBTRequestMatch.url("google.com"), response: SBTStubResponse(response: ["key": "value"], removeAfterIterations: 2)

// from here on the first two network requests containing 'google.com' will return a JSON {"key" : "value" }
// subsequent network requests won't be stubbed
...
```    

#### SBTStubResponse

The stubbing methods of the library require a `SBTStubResponse` object in order to determine what to return for network requests that have to be stubbed.

The class has a wide set of initializers that allow to specify data, HTTP headers, contentType, HTTP return code and response time of the stubbed request. For convenience some initializers omit some parameters which default to predefined values.

### Upload / Download items

#### Upload

```swift
let pathToFile = ... // path to file
app.uploadItem(atPath: pathToFile, toPath: "test_file.txt", relativeTo: .documentDirectory)
```    

#### Download

```swift
let uploadData = app.downloadItems(fromPath: "test_file.txt", relativeTo: .documentDirectory)
```    

### Network monitoring

This may come in handy when you need to check that specific network requests are made. You pass an `SBTRequestMatch` like for stubbing methods.

```swift
app.monitorRequests(matching: SBTRequestMatch.url("apple.com"))
    
// Interact with UI. Once ready flush calls and get the list of requests
    
let requests: [SBTMonitoredNetworkRequest] = app.monitoredRequestsFlushAll()
    
for request in requests {
    let requestBody  = request.request!.HTTPBody // HTTP Body in POST request?
    let responseJSON = request.responseJSON
    let requestTime  = request.requestTime // How long did the request take?
}
    
app.monitorRequestRemoveAll()
```    

### Throttling

The library allows to throttle network calls by specifying a response time, which can be a positive number of seconds or one of the predefined `SBTUITunnelStubsDownloadSpeed*`constants. You pass an `SBTRequestMatch` like for stubbing methods.

```swift
let throttleId = app.throttleRequests(matching: SBTRequestMatch.url("apple.com"), responseTime:SBTUITunnelStubsDownloadSpeed3G) ?? ""
    
app.throttleRequestRemove(withId: throttleId)
```    

### Block cookies

The library allows to block outgoing cookies in network calls. You pass an `SBTRequestMatch` like for stubbing methods.

```swift
let cookieBlockId = app.blockCookiesInRequests(matching: SBTRequestMatch.url("apple.com")) ?? ""
    
app.blockCookiesRequestsRemove(withId: cookieBlockId)
```    

### Rewrite

The library allows to rewrite the following elements of a network call:

- url
- request body
- request headers
- response body
- response headers
- response status code

To rewrite a network request you pass the appropriate `SBTRequestMatch` and `SBTRewrite` objects

#### SBTRewrite

The rewrite methods of the library require a `SBTRewrite` object in order to determine what to rewrite in the network requests that have to be rewritten.

The class has a wide set of initializers that allow to specify request and response body/headers, return status codes and URL.

The header rewrite is specified by passing a dictionary where the key will replace (if key already exist) or add new values to the headers. To remove a specific key just pass an empty value.

The other rewrite are specified by an array of `SBTRewriteReplacement`.

#### SBTRewriteReplacement

The `SBTRewriteReplacement` has a simple initializer where you pass 2 parameters: a regular expression that will be matched and a replacement string.


## User defaults access

You can interact with the app's NSUserDefaults as follows

#### Set object

```swift
app.userDefaultsSetObject("test_value" as NSCoding, forKey: "test_key")
```    

#### Get object

```swift
let obj = app.userDefaultsObject(forKey: "test_key")
```    
    
#### Remove object

```swift
app.userDefaultsRemoveObject(forKey: "test_key")
```

## Custom code blocks

You can easily add a custom block of code in the application target that can be conveniently invoked from the test target. An NSString identifies the block of code when registering and invoking it.

#### Application target

You register a block of code that will be invoked from the test target as follows:

```swift
SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandKey") {
    injectedObject in
    // this block will be invoked from app.performCustomCommandNamed()

    return "Any object conforming to NSCoding that you want to pass back to test target"
}
````

**Note** It is your responsibility to unregister the custom command when it is no longer needed. Failing to do so may end up with unexpected behaviours.

#### Test target

You invoke the custom command by using the same identifier used on registration, optionally passing an NSObject:

```swift
let objReturnedByBlock = app.performCustomCommandNamed("myCustomCommand", object: someObjectToInject)
```

## Fine grain scrolling

The tunnel adds methods to perform fine grain scrolling for table/collection/scroll views


### UITableView

Pass the accessibility label/identifier of the table along with the row you want to scroll to. The row is an int which is section-wise flattened, if you want to scroll to last cell you can pass Int.max or any integer greater than the number of items in datasource

```swift
app.scrollTableView(withIdentifier: "identifier", toRow: .max, animated: false)
```

### UICollectionView

Pass the accessibility label/identifier of the collection along with the row you want to scroll to. The row is an int which is section-wise flattened, if you want to scroll to last cell you can pass Int.max or any integer greater than the number of items in datasource

```swift
app.scrollCollectionView(withIdentifier: "identifier", toRow: .max, animated: false)
```

### UIScrollview scrolling

Pass the accessibility label/identifier of the collection along with the accesibility lable/identifier of an element contained in the scrollview you want to scroll to.

```swift
app.scrollScrollViewWithIdentifier(withIdentifier: "identifier", toElementWitIdentifier: .max, animated: false)
```

## CLLocationManager stubbing

It is possible to enable CLLocationManager stubbing in order to test that your app properly responds to the various authorization statuses and location change event.

Disable the system location engine and enable stubbing (startMonitoring, stopMonitoring and other similar methods will become nops)

```swift
app.coreLocationStubEnabled(true)
```

Once enabled the default value for `+[CLLocationManager authorizationStatus]` will be `kCLAuthorizationStatusAuthorizedAlways` and `+[CLLocationManager locationServicesEnabled]` will be `YES`.

### authorizationStatus

When stubbing is enable you can change the value that will be returned by `+[CLLocationManager authorizationStatus]` using

```swift
app.coreLocationStubAuthorizationStatus(.denied)
```

### locationServicesEnabled

When stubbing is enable you can change the value that will be returned by `+[CLLocationManager locationServicesEnabled]` using

```swift
app.coreLocationStubLocationServicesEnabled(false)
```

### Trigger location updates

When stubbing is enable you can trigger a location change by using

```swift
let locations: [CLLocation] = ...
app.coreLocationNotifyLocationUpdate(locations)
```

### Trigger location update failure

When stubbing is enable you can trigger a location change by using

```swift
let errror: Error = ...
app.coreLocationNotifyLocationError(errror)
```

## UNUserNotificationCenter stubbing

It is possible to enable UNUserNotificationCenter stubbing in order to test that your app properly responds to the various authorization statuses.

Disable the system notification engine and enable stubbing

```swift
app.notificationCenterStubEnabled(true)
```

Once enabled the default value for `-[UNNotificationSettings authorizationStatus]` will be `UNAuthorizationStatusAuthorized`.

### authorizationStatus

When stubbing is enable you can change the value that will be returned by `-[UNNotificationSettings authorizationStatus]` using

```swift
app.notificationCenterStubAuthorizationStatus(.denied)
```

## WKWebview stubbing

WKWebViews do not natively support NSURLProtocol which is used by SBTUITestTunnel to intercepect network requests allowing for stubbing/throttling/monitoring. To interact with network requests generated inside WKWebViews you'll neet to explicitly opt-in by invoking:

```swift
app.wkWebViewStubEnabled(true)
```

**IMPORTANT NOTICE**

Beware that to support NSURLProtocol inside WKWebViews we're calling internal APIs that have a side effect that body of POST requests generated inside the WKWebView are stripped away.
