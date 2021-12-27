# Installation (Swift Package Manager)

From the _File_ menu select _Add Packages..._. Enter `https://github.com/Subito-it/SBTUITestTunnel` in the Package URL. Select the package and **select the `master` _branch_** as _Dependency Rule_.

Now add the `SBTUITestTunnelServer` package to your main app target and `SBTUITestTunnelClient` to your UI test target.

# Installation (CocoaPods)

Your Podfile should include the sub project `SBTUITestTunnelServer` for the app target and `SBTUITestTunnelClient` for the UI test target.

```ruby
use_frameworks!

target 'APP_TARGET' do
  pod 'SBTUITestTunnelServer'
  pod 'GCDWebServer', :inhibit_warnings => true
end

target 'UITESTS_TARGET' do
  pod 'SBTUITestTunnelClient'
end
```

# Installation (Manual)

1. Add the `Server` folder to the app target
2. Add the `Client` folder to the ui test target
3. Add the `Common` folder to both targets
4. Download the latest release of [GCDWebServer](https://github.com/swisspol/GCDWebServer) then add the all the files under GCDWebServer/Core, GCDWebServer/Requests and GCDWebServer/Responses to a single `GCDWebServer` subfolder to your Xcode project.
5. Add $(SDKROOT)/<path to the GCDWebserver folder in 4.> to your header search paths (via Target > Build Settings > HEADER_SEARCH_PATHS)
5. Link to libz (via Target > Build Phases > Link Binary With Libraries)

If you're on an Objective-C project
1. In your AppDelegate #import "SBTUITestTunnelServer.h" and call [SBTUITestTunnelServer takeOff] as the first line in appDidFinishLaunching. **You need to wrap the import statement around an #if DEBUG conditional**, see [Setup](Setup.md) section for additional details.
2. Add #import "SBTUITunneledApplication.h" and #import "XCTestCase+AppExtension.h" on top of all your UI Test Cases files

If you're on a Swift project:
1. Add "SBTUITestTunnelServer.h" to the Application's bridging header file and call SBTUITestTunnelServer.takeOff() as the first line in appDidFinishLaunching. **You need to wrap the import statement around an #if DEBUG conditional**, see [Setup](Setup.md) section for additional details.
2. Add #import "SBTUITunneledApplication.h" and #import "XCTestCase+AppExtension.h" to your UITesting's bridging headers files
