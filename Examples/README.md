# SBTUITestTunnel Examples

This directory contains example projects demonstrating how to integrate SBTUITestTunnel with different iOS application architectures and dependency management approaches.

## Available Examples

### 🏗️ UIKit Example (CocoaPods)
**Location**: `UIKit/`
**Tech Stack**: UIKit + CocoaPods + XcodeGen

Demonstrates the **traditional iOS development approach** with:
- UIKit-based user interface
- CocoaPods for dependency management
- Comprehensive UI test suite (20+ test files)
- NoSwizzling test configuration

**Quick Start**:
```bash
cd UIKit
pod install
xcodegen generate
open SBTUITestTunnel_UIKit.xcworkspace
```

### 🚀 SwiftUI Example (SwiftPM)
**Location**: `SwiftUI/`
**Tech Stack**: SwiftUI + Swift Package Manager + XcodeGen

Demonstrates the **modern iOS development approach** with:
- SwiftUI-based user interface
- Swift Package Manager for dependencies
- SwiftUI-specific UI test suite
- Streamlined project structure

**Quick Start**:
```bash
cd SwiftUI
xcodegen generate
open SBTUITestTunnel_SwiftUI.xcodeproj
```

## Architecture Overview

### UIKit Example Structure
```
UIKit/
├── project.yml              # XcodeGen configuration
├── Podfile                  # CocoaPods dependencies
├── App/                     # UIKit demo application
│   ├── SBTAppDelegate.m/h   # App delegate
│   ├── SBTTableViewController.swift
│   ├── Main.storyboard      # Interface Builder files
│   └── ...more UI files
└── UITests/                 # Comprehensive test suite
    ├── StubTests.swift      # Network stubbing tests
    ├── MonitorTests.swift   # Network monitoring tests
    ├── RewriteTests.swift   # Request rewriting tests
    └── NoSwizzlingTests/    # Tests without swizzling
```

### SwiftUI Example Structure
```
SwiftUI/
├── project.yml              # XcodeGen configuration
├── App/                     # SwiftUI demo application
│   ├── SBTUITestTunnel_Example_SwiftUIApp.swift
│   ├── ContentView.swift    # Main SwiftUI view
│   ├── TestManager.swift    # Demo functionality
│   └── Assets.xcassets
└── UITests/                 # SwiftUI-focused test suite
    ├── StubTests.swift      # SwiftUI-specific tests
    ├── MonitorTests.swift   # Network monitoring
    └── ...more test files
```

## Choosing the Right Example

### Use the UIKit Example when:
- ✅ Working with existing UIKit-based projects
- ✅ Using CocoaPods as your primary dependency manager
- ✅ Need comprehensive network testing examples
- ✅ Want to see traditional iOS testing patterns

### Use the SwiftUI Example when:
- ✅ Building new SwiftUI applications
- ✅ Preferring Swift Package Manager
- ✅ Want modern iOS development patterns
- ✅ Need streamlined project structure

## Testing Both Examples

### UIKit Tests
```bash
# Standard tests
xcodebuild -workspace UIKit/SBTUITestTunnel_UIKit.xcworkspace \
           -scheme UIKit_Example \
           -destination 'platform=iOS Simulator,name=iPhone 15' \
           test

# NoSwizzling tests
xcodebuild -workspace UIKit/SBTUITestTunnel_UIKit.xcworkspace \
           -scheme UIKit_NoSwizzling_Tests \
           -destination 'platform=iOS Simulator,name=iPhone 15' \
           test
```

### SwiftUI Tests
```bash
xcodebuild -project SwiftUI/SBTUITestTunnel_SwiftUI.xcodeproj \
           -scheme SwiftUI_Example \
           -destination 'platform=iOS Simulator,name=iPhone 15' \
           test
```

## Integration Patterns

Both examples demonstrate:
- 🔧 **Server Setup**: How to initialize SBTUITestTunnelServer in your app
- 🧪 **Client Usage**: How to use SBTUITestTunnelClient in your tests
- 🌐 **Network Stubbing**: Intercepting and mocking network requests
- 📊 **Network Monitoring**: Observing network traffic during tests
- ⚡ **Request Rewriting**: Modifying requests on-the-fly
- 🎯 **Custom Matchers**: Creating targeted network interceptions

## Contributing

When adding new functionality to SBTUITestTunnel:
1. Update both examples to demonstrate the new feature
2. Add corresponding test cases to both test suites
3. Update README files with new integration patterns
4. Ensure both examples build and test successfully

## Migration Guide

If you're migrating from the old multi-target Example structure:
- **UIKit projects** → Use the `UIKit`
- **SwiftUI projects** → Use the `SwiftUI`
- **Mixed projects** → Reference both examples as needed

The new structure provides clearer separation of concerns and better demonstrates real-world integration patterns for each UI framework.