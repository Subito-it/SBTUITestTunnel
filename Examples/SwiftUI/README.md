# SwiftUI Example - SBTUITestTunnel

This example demonstrates how to integrate SBTUITestTunnel with a SwiftUI-based iOS application using Swift Package Manager.

## Setup

1. **Generate Project**:
   ```bash
   cd Examples/SwiftUI
   xcodegen generate
   ```

2. **Open Project**:
   ```bash
   open SBTUITestTunnel_SwiftUI.xcodeproj
   ```

   Swift Package dependencies will be resolved automatically when you open the project.

## Available Schemes

- **SwiftUI**: Main scheme for running the SwiftUI demo app and its UI tests

## Running Tests

```bash
xcodebuild -project SBTUITestTunnel_SwiftUI.xcodeproj \
           -scheme SwiftUI \
           -destination 'platform=iOS Simulator,name=iPhone 15' \
           test
```

## Project Structure

```
SwiftUI/
├── project.yml              # XcodeGen configuration
├── App/                     # SwiftUI demo application
│   ├── ContentView.swift
│   ├── App.swift
│   └── Info.plist
└── UITests/                 # UI test suite
    ├── StubTests.swift
    ├── MonitorTests.swift
    └── ...more test files
```

## Integration Notes

This example shows the **modern iOS development approach**:
- **Dependency Management**: Swift Package Manager
- **UI Framework**: SwiftUI
- **Project Generation**: XcodeGen

### Package Dependencies

The project automatically resolves these Swift Package dependencies:
- `SBTUITestTunnelServer` (for the main app)
- `SBTUITestTunnelClient` (for UI tests)

For the traditional UIKit + CocoaPods approach, see the `UIKit` directory.