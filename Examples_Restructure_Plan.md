# SBTUITestTunnel Examples Restructure Plan

## Overview

This document outlines the plan to restructure the SBTUITestTunnel Examples directory from the current complex multi-target setup to a simplified two-project structure:
- **UIKit Example**: CocoaPods + XcodeGen
- **SwiftUI Example**: SwiftPM + XcodeGen

## Current State Analysis

### Current Structure Problems
- **Complex Configuration**: Single `project.yml` with 5 targets
- **Mixed Dependencies**: Both CocoaPods and SPM in same workspace
- **Confusing Setup**: Developers must understand the entire complex structure
- **Maintenance Overhead**: Multiple schemes, targets, and configurations to maintain
- **Duplicate SPM Directory**: Separate SPM example that duplicates functionality

### Current Targets
1. `SBTUITestTunnel_Example_UIKit` - UIKit demo app
2. `SBTUITestTunnel_Example_SwiftUI` - SwiftUI demo app
3. `SBTUITestTunnel_Tests` - UI tests for UIKit app
4. `SBTUITestTunnel_TestsNoSwizzling` - UI tests with swizzling disabled
5. `SBTUITestTunnel_SwiftUI_Tests` - UI tests for SwiftUI app

### Current Build Systems
- Main project uses CocoaPods + XcodeGen
- Separate SPM directory with its own project structure
- Complex Podfile with multiple targets
- Intricate `project.yml` with dependencies between targets

## Target Structure

### Proposed Directory Layout
```
Examples/
├── UIKitExample/
│   ├── project.yml                  # Simple XcodeGen config
│   ├── Podfile                      # CocoaPods dependencies
│   ├── App/                         # UIKit demo app source
│   │   ├── AppDelegate.swift
│   │   ├── ViewController.swift
│   │   ├── Info.plist
│   │   └── Assets/
│   ├── UITests/                     # UI tests source
│   │   ├── BasicUITests.swift
│   │   ├── NetworkUITests.swift
│   │   ├── Info.plist
│   │   └── NoSwizzlingTests/        # Tests with swizzling disabled
│   └── README.md                    # UIKit-specific setup instructions
└── SwiftUIExample/
    ├── project.yml                  # Simple XcodeGen config
    ├── Package.swift                # SwiftPM dependencies (optional)
    ├── App/                         # SwiftUI demo app source
    │   ├── ContentView.swift
    │   ├── App.swift
    │   ├── Info.plist
    │   └── Assets/
    ├── UITests/                     # UI tests source
    │   ├── BasicUITests.swift
    │   ├── NetworkUITests.swift
    │   └── Info.plist
    └── README.md                    # SwiftUI-specific setup instructions
```

### Technology Alignment
- **UIKit Example**: Uses CocoaPods (traditional iOS dependency management)
- **SwiftUI Example**: Uses SwiftPM packages (modern iOS dependency management)
- **Both**: Use XcodeGen for project file generation (consistent tooling)

## Migration Steps

### Phase 1: Preparation
1. **Backup Current State**
   - Create feature branch for restructure
   - Document current test coverage
   - Verify all current tests pass

2. **Analyze Current Code**
   - Identify shared code between UIKit and SwiftUI examples
   - Map current test scenarios to new structure
   - Document any UIKit-specific or SwiftUI-specific features

### Phase 2: Create New Structure

3. **Create UIKit Example Project**
   - Create `Examples/UIKitExample/` directory
   - Write simplified `project.yml` for UIKit
   - Create new `Podfile` specific to UIKit example
   - Write UIKit-specific README

4. **Create SwiftUI Example Project**
   - Create `Examples/SwiftUIExample/` directory
   - Write simplified `project.yml` for SwiftUI
   - Configure SwiftPM package dependencies
   - Write SwiftUI-specific README

### Phase 3: Migrate Source Code

5. **Migrate UIKit App Source**
   - Copy relevant files from current UIKit target
   - Update imports and dependencies
   - Ensure app builds and runs correctly

6. **Migrate SwiftUI App Source**
   - Copy relevant files from current SwiftUI target
   - Update imports and dependencies
   - Ensure app builds and runs correctly

7. **Migrate Test Code**
   - Copy and adapt UI tests for UIKit example
   - Copy and adapt UI tests for SwiftUI example
   - Implement NoSwizzling tests via build configuration
   - Ensure all tests pass

### Phase 4: Configuration

8. **Setup Build Configurations**
   - Configure Debug/Release builds for both examples
   - Setup proper code signing
   - Configure test schemes

9. **Update CI/CD**
   - Update GitHub Actions to build both examples
   - Add separate CI jobs for UIKit and SwiftUI examples
   - Ensure test coverage is maintained

### Phase 5: Documentation and Cleanup

10. **Update Documentation**
    - Update main README.md with new structure
    - Write comprehensive setup instructions for each example
    - Update any references to old structure

11. **Cleanup Old Structure**
    - Remove old complex `project.yml`
    - Remove old `Podfile`
    - Remove SPM directory (functionality moved to SwiftUI example)
    - Remove old source directories

12. **Verify Migration**
    - Test both examples from clean checkouts
    - Verify all test scenarios still work
    - Confirm CI/CD passes

## Configuration Files

### UIKit Example project.yml
```yaml
name: SBTUITestTunnel_UIKit_Example

options:
  bundleIdPrefix: com.subito.uitest.uikit
  postGenCommand: "pod install"

targets:
  App:
    type: application
    platform: iOS
    deploymentTarget: "15.0"
    sources: [App]
    dependencies:
      - sdk: UIKit.framework
      - sdk: Foundation.framework
    settings:
      base:
        INFOPLIST_FILE: "App/Info.plist"

  UITests:
    type: bundle.ui-testing
    platform: iOS
    deploymentTarget: "15.0"
    sources: [UITests]
    dependencies:
      - target: App
    settings:
      base:
        INFOPLIST_FILE: "UITests/Info.plist"

  UITestsNoSwizzling:
    type: bundle.ui-testing
    platform: iOS
    deploymentTarget: "15.0"
    sources: [UITests]
    dependencies:
      - target: App
    settings:
      base:
        INFOPLIST_FILE: "UITests/Info.plist"
        GCC_PREPROCESSOR_DEFINITIONS: ["DISABLE_UITUNNEL_SWIZZLING=1"]

schemes:
  UIKit_Example:
    build:
      targets:
        App: [all]
    test:
      targets: [UITests]

  UIKit_NoSwizzling_Tests:
    build:
      targets:
        App: [all]
    test:
      targets: [UITestsNoSwizzling]
```

### SwiftUI Example project.yml
```yaml
name: SBTUITestTunnel_SwiftUI_Example

options:
  bundleIdPrefix: com.subito.uitest.swiftui

packages:
  SBTUITestTunnelServer:
    path: ../..
  SBTUITestTunnelClient:
    path: ../..

targets:
  App:
    type: application
    platform: iOS
    deploymentTarget: "15.0"
    sources: [App]
    dependencies:
      - package: SBTUITestTunnelServer
      - sdk: SwiftUI.framework
      - sdk: Foundation.framework
    settings:
      base:
        INFOPLIST_FILE: "App/Info.plist"

  UITests:
    type: bundle.ui-testing
    platform: iOS
    deploymentTarget: "15.0"
    sources: [UITests]
    dependencies:
      - target: App
      - package: SBTUITestTunnelClient
    settings:
      base:
        INFOPLIST_FILE: "UITests/Info.plist"

schemes:
  SwiftUI_Example:
    build:
      targets:
        App: [all]
    test:
      targets: [UITests]
```

### UIKit Example Podfile
```ruby
source "https://cdn.cocoapods.org/"
platform :ios, "15.0"
use_frameworks!

target "App" do
  pod "SBTUITestTunnelServer", :path => "../.."
  pod "SBTUITestTunnelCommon", :path => "../.."
end

target "UITests" do
  pod "SBTUITestTunnelServer", :path => "../.."
  pod "SBTUITestTunnelClient", :path => "../.."
  pod "SBTUITestTunnelCommon", :path => "../.."
end

target "UITestsNoSwizzling" do
  pod "SBTUITestTunnelServer", :path => "../.."
  pod "SBTUITestTunnelClient", :path => "../.."
  pod "SBTUITestTunnelCommon", :path => "../.."
end
```

## Benefits of New Structure

### For Developers
- **Simpler Setup**: Each example is self-contained
- **Clear Technology Demos**: UIKit shows CocoaPods workflow, SwiftUI shows SwiftPM workflow
- **Easier Contribution**: Developers can focus on one UI framework
- **Better Learning**: Each example serves as a complete integration guide

### For Maintenance
- **Reduced Complexity**: No more complex multi-target configurations
- **Independent Testing**: Each example can be tested separately
- **Cleaner CI**: Separate build jobs for each approach
- **Easier Debugging**: Issues are isolated to specific examples

### For the Project
- **Better Documentation**: Each example has focused documentation
- **Clearer Use Cases**: Demonstrates both traditional and modern iOS approaches
- **Easier Adoption**: Developers can choose the approach that fits their project

## Risk Assessment

### Low Risk
- Both examples will use proven, simple configurations
- XcodeGen is already used successfully in the project
- Core framework remains unchanged

### Mitigation Strategies
- Thorough testing at each migration step
- Maintain current test coverage
- Keep old structure in version control until migration is verified
- Clear rollback plan if issues arise

## Success Criteria

1. **Functionality**: Both examples build, run, and test successfully
2. **Simplicity**: Each example has a simple, understandable structure
3. **Documentation**: Clear setup instructions for each example
4. **CI/CD**: Automated testing works for both examples
5. **Developer Experience**: New contributors can easily understand and use examples

## Timeline Estimate

- **Phase 1 (Preparation)**: 1-2 days
- **Phase 2 (Structure Creation)**: 1 day
- **Phase 3 (Code Migration)**: 2-3 days
- **Phase 4 (Configuration)**: 1-2 days
- **Phase 5 (Documentation/Cleanup)**: 1-2 days

**Total Estimated Time**: 6-10 days

## Next Steps

1. Review and approve this plan
2. Create feature branch for restructure work
3. Begin Phase 1 preparation work
4. Execute migration phases sequentially
5. Thorough testing and validation
6. Merge to main branch

---

*This document will be updated as the migration progresses and any issues or improvements are identified.*