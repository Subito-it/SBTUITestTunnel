# UIKit Example - SBTUITestTunnel

This example demonstrates how to integrate SBTUITestTunnel with a UIKit-based iOS application using CocoaPods.

## Setup

1. **Install Dependencies**:
   ```bash
   cd Examples/UIKit
   pod install
   ```

2. **Generate Project**:
   ```bash
   xcodegen generate
   ```

3. **Open Workspace**:
   ```bash
   open SBTUITestTunnel_UIKit.xcworkspace
   ```

## Available Schemes

- **UIKit**: Main scheme for running the UIKit demo app and its standard UI tests
- **UIKit_NoSwizzling_Tests**: Scheme for running UI tests with method swizzling disabled

## Running Tests

### Standard Tests
```bash
xcodebuild -workspace SBTUITestTunnel_UIKit.xcworkspace \
           -scheme UIKit \
           -destination 'platform=iOS Simulator,name=iPhone 15' \
           test
```

### NoSwizzling Tests
```bash
xcodebuild -workspace SBTUITestTunnel_UIKit.xcworkspace \
           -scheme UIKit_NoSwizzling_Tests \
           -destination 'platform=iOS Simulator,name=iPhone 15' \
           test
```

## Project Structure

```
UIKit/
├── project.yml              # XcodeGen configuration
├── Podfile                  # CocoaPods dependencies
├── App/                     # UIKit demo application
│   ├── AppDelegate.swift
│   ├── ViewController.swift
│   └── Info.plist
└── UITests/                 # UI test suite
    ├── StubTests.swift
    ├── MonitorTests.swift
    └── ...more test files
```

## Integration Notes

This example shows the **traditional iOS development approach**:
- **Dependency Management**: CocoaPods
- **UI Framework**: UIKit
- **Project Generation**: XcodeGen

For the modern SwiftUI + SwiftPM approach, see the `SwiftUI` directory.