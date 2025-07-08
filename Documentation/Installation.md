# 📦 Installation Guide

SBTUITestTunnel supports multiple installation methods to fit your project's needs. Choose the option that works best for your setup.

## 🎯 Swift Package Manager (Recommended)

The easiest and most modern way to integrate SBTUITestTunnel into your project.

1. In Xcode, navigate to **File → Add Package Dependencies...**
2. Enter the repository URL: 
   ```
   https://github.com/Subito-it/SBTUITestTunnel
   ```
3. For **Dependency Rule**, select the `master` branch
4. Add the packages to your targets:
   - **`SBTUITestTunnelServer`** → Your main app target
   - **`SBTUITestTunnelClient`** → Your UI test target

## 🍫 CocoaPods

Perfect for projects already using CocoaPods dependency management.

Add the following to your `Podfile`:

```ruby
use_frameworks!

target 'YourAppTarget' do
  pod 'SBTUITestTunnelServer'
end

target 'YourUITestTarget' do
  pod 'SBTUITestTunnelClient'
end
```

Then run:
```bash
pod install
```

## 🔧 Manual Installation

For projects that require manual dependency management.

### Step 1: Add Source Files

1. **Server Components**: Add the `Sources/SBTUITestTunnelServer` folder to your app target
2. **Client Components**: Add the `Sources/SBTUITestTunnelClient` folder to your UI test target  
3. **Common Components**: Add the `Sources/SBTUITestTunnelCommon` folder to **both** targets

### Step 2: Configure Build Settings

1. **Link Libraries**: Add `libz.tbd` in **Build Phases → Link Binary With Libraries**

### Step 3: Project-Specific Configuration

#### For Swift Projects

1. **App Target**: Add `#import "SBTUITestTunnelServer.h"` to your bridging header
2. **UI Test Target**: Add these imports to your test bridging header:
   ```objc
   #import "SBTUITunneledApplication.h"
   #import "XCTestCase+AppExtension.h"
   ```

#### For Objective-C Projects

1. **App Target**: Import in your `AppDelegate.m`:
   ```objc
   #import "SBTUITestTunnelServer.h"
   ```
2. **UI Test Target**: Import in your test files:
   ```objc
   #import "SBTUITunneledApplication.h"
   #import "XCTestCase+AppExtension.h"
   ```

---

⚠️ **Important**: Always wrap SBTUITestTunnel imports in `#if DEBUG` conditionals to prevent inclusion in production builds. See the [Setup Guide](./Setup.md) for details.
