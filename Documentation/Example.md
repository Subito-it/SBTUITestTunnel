# Example Apps

The repository includes UIKit and SwiftUI apps that exercise the tunnel with the same UI test suite. Run these commands from the repository root. Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen) are required; the CocoaPods example also requires CocoaPods.

## SwiftUI with Swift Package Manager

```bash
xcodegen generate --spec Examples/SwiftUI/project.yml
open Examples/SwiftUI/SBTUITestTunnel_SwiftUI.xcodeproj
```

Select the **SwiftUI** scheme and an iPhone simulator, then press **⌘U**. The project uses the local package at the repository root.

The app demonstrates network requests, WebSockets, user defaults, location and notification stubbing, custom commands, and scrolling through SwiftUI lists, grids, and scroll views. Its startup configuration is described in the [setup guide](./Setup.md).

## UIKit with Swift Package Manager

```bash
xcodegen generate --spec Examples/UIKit/SPM/project.yml
open Examples/UIKit/SPM/SBTUITestTunnel.xcodeproj
```

Select **SBTUITestTunnel_Tests** and press **⌘U**. This builds the UIKit example app and runs the shared tests using the local package, without CocoaPods.

## UIKit with CocoaPods

```bash
xcodegen generate --spec Examples/UIKit/project.yml
cd Examples/UIKit
pod install
open SBTUITestTunnel.xcworkspace
```

Select **SBTUITestTunnel_Tests** and press **⌘U**. Use **SBTUITestTunnel_NoSwizzlingTests** for the manual client integration tests. The **MultiSceneExample** scheme tests launch ordering and additional windows; choose an **iPad simulator** so the multi-window test can run.

## Running from the Command Line

After generating the relevant project and resolving its dependencies:

```bash
Scripts/run_uitests.rb Examples/SwiftUI/SBTUITestTunnel_SwiftUI.xcodeproj SwiftUI
Scripts/run_uitests.rb Examples/UIKit/SPM/SBTUITestTunnel.xcodeproj SBTUITestTunnel_Tests
Scripts/run_uitests.rb Examples/UIKit/SBTUITestTunnel.xcworkspace SBTUITestTunnel_Tests
Scripts/run_uitests_no_swizzling.rb Examples/UIKit/SBTUITestTunnel.xcworkspace
Scripts/run_uitests_multiscene.rb Examples/UIKit/SBTUITestTunnel.xcworkspace
```

The scripts select an available device on the newest installed iOS simulator runtime by UDID. Multi-scene tests select an iPad; the other suites select an iPhone. To choose an installed device and iOS version explicitly, append its name and a version prefix:

```bash
Scripts/run_uitests.rb Examples/SwiftUI/SBTUITestTunnel_SwiftUI.xcodeproj SwiftUI 'iPhone 17' '26'
```

An unavailable requested device or runtime fails with an error. Results are written to `<scheme>.xcresult` in the current directory.

## Exploring the Tests

`Examples/SharedUITests` contains the tests used by both apps:

- `StubTests.swift`, `MonitorTests.swift`, `RewriteTests.swift`, and `ThrottleTest.swift` cover network interception.
- `CoreLocationTests.swift`, `NotificationCenterTests.swift`, and `UserDefaultsTests.swift` cover app state and system APIs.
- `ScrollContentTests.swift` covers scrolling; each app supplies its own UIKit or SwiftUI views.
- `KeepAliveTests.swift`, `RedirectTests.swift`, and `ProxyURLProtocolClientTests.swift` cover HTTP behavior.

Start with the launch setup in `XCTestCase+Extension.swift`, then compare the app implementations under `Examples/UIKit` and `Examples/SwiftUI`. See the [usage guide](./Usage.md) for individual APIs and the [setup guide](./Setup.md) to integrate your own app.
