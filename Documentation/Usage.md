# Usage

`SBTUITunneledApplication`'s headers are well commented making the library's functionality self explanatory. You can also checkout the UI test target in the example project which show basic usage of the library.


## Startup

At launch you can optionally provide some options and a startup block which will be executed synchronously with app's launch. This is the right place to prepare (inject files, modify NSUserDefaults, etc) the app's startup status.

### Launch with no options

You launch your tests in a similar fashion as you're used to.

    import SBTUITestTunnel

    class MyTestClass: XCTestCase {xw
        override func setUp() {
            super.setUp()
            
            app.launchTunnel()
        }
        
        func testStuff() {
            // ... 
        }
    }

_Note how we don't need to instantiate the `app` property_ 

### Launch with options and startupBlock

    app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem]) {
         // do additional setup before the app launches
         // i.e. prepare stub request, start monitoring requests
    }

- `SBTUITunneledApplicationLaunchOptionResetFilesystem` will delete the entire app's sandbox filesystem
- `SBTUITunneledApplicationLaunchOptionDisableUITextFieldAutocomplete` disables UITextField's autocomplete functionality which can lead to unexpected results when typing text.

## Framework classes

### SBTRequestMatch

The stubbing/monitoring/throttling methods of the library require a `SBTRequestMatch` object in order to determine whether they should react to a network request.

You can specify a regex on the URL, multiple regex on the query (in `POST` and `PUT` requests they will match against the body) and HTTP method using one of the several class methods available.

#### Query parameter

The `query` parameter found in different `SBTRequestMatch` initializers is an array of regex strings that are checked with the request [query](https://tools.ietf.org/html/rfc3986#section-3.4). If all regex in array match the request is stubbed/monitored/throttled.

In a kind of unconventional syntax you can prefix the regex with and exclamation mark `!` to specify that the request must not match that specific regex, see the following examples.

#### Examples

The regex in `GET` and `DELETE` requests will match the entire URL including query parameters.

Below some matches for a sample request like http://wwww.myhost.com/v1/user/281218/info?param1=val1&param2=val2 :

    // this will match the request independently of the query parameters
    let sr = SBTRequestMatch.url("myhost.com/v1/user/281218/info")
    // this will match the request independently of the query parameters for any user id
    let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info")
    // this will match the request containing query parameters
    let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info\?param1=val1&param2=val2")
    // this will match the request containing only param1 = val1 query
    let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info\?.*param1=val1")

**Given that parameter order isn't guaranteed** it is recommended to specify the `query` parameter in the `SBTRequestMatch`'s initializer. This is an array of regex that need to fulfill all for the request to match.

Considering the previous example the following `SBTRequestMatch` will match if the request contains `param1=val1` AND `param2=val2`.

    let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info", query: ["&param1=val1", "&param2=val2"])
    let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info", query: ["&param2=val2", "&param1=val1"])
    
You can additionally specify that the query should not contain something by prefixing the regex with an exclamantion mark `!`:

    let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info", query: ["&param1=val1", "&param2=val2", "!param3=val3"])

This will match if the query contains `param1=val1` AND `param2=val2` AND NOT `param3=val3`

Finally you can limit a specific HTTP method by specifying it in the `method` parameter.

    // will match GET request only
    let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info", query: ["&param1=val1", "&param2=val2"], method: "GET")
    let sr = SBTRequestMatch.url("myhost.com/v1/user/.*/info", method: "GET")

### SBTStubResponse

The stubbing methods of the library require a `SBTStubResponse` object in order to determine what to return for network requests that have to be stubbed.

The class has a wide set of initializers that allow to specify data, HTTP headers, contentType, HTTP return code and response time of the stubbed request. For convenience some initializers omit some parameters which default to predefined values.

## Stubbing

To stub a network request you pass the appropriate `SBTRequestMatch` and `SBTStubResponse` objects

    let stubId = app.stubRequests(matching: SBTRequestMatch.url("google.com"), response: SBTStubResponse(response: ["key": "value"])

    // from here on network requests containing 'google.com' will return a JSON {"key" : "value" }
    ...

    app.stubRequestsRemoveWithId(stubId) // To remove the stub either use the identifier

    app.stubRequestsRemoveAll() // or remove all active stubs

A second stub initializer is available that automatically removes the stub after a certain number of times that the request is matched.

    let stubId = app.stubRequests(matching: SBTRequestMatch.url("google.com"), response: SBTStubResponse(response: ["key": "value"], removeAfterIterations: 2)

    // from here on the first two network requests containing 'google.com' will return a JSON {"key" : "value" }
    // subsequent network requests won't be stubbed
    ...


## NSUserDefaults

### Set object

    app.userDefaultsSetObject("test_value" as NSCoding, forKey: "test_key");

### Get object

    let obj = app.userDefaultsObject(forKey: "test_key")
    
### Remove object

    app.userDefaultsRemoveObject(forKey: "test_key")


## Upload / Download items

### Upload

    let pathToFile = ... // path to file
    app.uploadItem(atPath: pathToFile, toPath: "test_file.txt", relativeTo: .documentDirectory)

### Download

    let uploadData = app.downloadItems(fromPath: "test_file.txt", relativeTo: .documentDirectory)

## Network monitoring

This may come handy when you need to check that specific network requests are made. You pass an `SBTRequestMatch` like for stubbing methods.

    app.monitorRequests(matching: SBTRequestMatch.url("apple.com"))
        
    // Interact with UI. Once ready flush calls and get the list of requests
        
    let requests: [SBTMonitoredNetworkRequest] = app.monitoredRequestsFlushAll()
        
    for request in requests {
        let requestBody  = request.request!.HTTPBody // HTTP Body in POST request?
        let responseJSON = request.responseJSON
        let requestTime  = request.requestTime // How long did the request take?
    }
        
    app.monitorRequestRemoveAll()

## Throttling

The library allows to throttle network calls by specifying a response time, which can be a positive number of seconds or one of the predefined `SBTUITunnelStubsDownloadSpeed*`constants. You pass an `SBTRequestMatch` like for stubbing methods.

    let throttleId = app.throttleRequests(matching: SBTRequestMatch.url("apple.com"), responseTime:SBTUITunnelStubsDownloadSpeed3G) ?? ""
        
     app.throttleRequestRemove(withId: throttleId)

## Custom defined blocks of code

You can easily add a custom block of code in the application target that can be conveniently invoked from the test target. An NSString identifies the block of code when registering and invoking it.

### Application target

You register a block of code that will be invoked from the test target as follows:

    SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandKey") {
        injectedObject in
        // this block will be invoked from app.performCustomCommandNamed()

        return "Any object you want to pass back to test target"
    }

**Note** It is your responsibility to unregister the custom command when it is no longer needed. Failing to do so may end up with unexpected behaviours.

### Test target

You invoke the custom command by using the same identifier used on registration, optionally passing an NSObject:

    let objReturnedByBlock = app.performCustomCommandNamed("myCustomCommand", object: someObjectToInject)