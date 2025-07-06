# 📱 Example Project Guide

The SBTUITestTunnel example project provides a hands-on demonstration of all the library's features. This guide will help you set up and explore the example app to better understand how to use SBTUITestTunnel in your own projects.

## 🚀 Quick Start

### Prerequisites

- **Xcode** (latest version recommended)
- **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** for project generation

### Installation & Setup

1. **Install XcodeGen** (if not already installed):
   ```bash
   brew install xcodegen
   ```

2. **Navigate to the Example Directory**:
   ```bash
   cd Example
   ```

3. **Generate and Open the Project**:
   ```bash
   xcodegen && xed .
   ```

This will generate the `SBTUITestTunnel.xcodeproj` file and open it in Xcode.

## 🧪 Running the Tests

Once the project is open in Xcode:

1. **Select the Scheme**: Choose **SBTUITestTunnel_Example** from the scheme selector
2. **Choose Target**: Select a simulator or connected device
3. **Run UI Tests**: Press **⌘U** or go to **Product → Test**

## 🔍 What You'll Find

The example project demonstrates:

### 🌐 Network Features
- **Request Stubbing** - Mock API responses with custom data
- **Network Monitoring** - Track and analyze network requests
- **Request Throttling** - Simulate different network speeds
- **Cookie Blocking** - Prevent cookies from being sent
- **Request Rewriting** - Modify requests and responses on-the-fly

### 📱 Device Simulation
- **Core Location Stubbing** - Mock GPS locations and authorization states
- **User Notifications** - Test notification permissions without user interaction
- **User Defaults** - Manipulate app preferences during tests

### 🔧 Advanced Features
- **Custom Code Execution** - Run arbitrary code within the app's context
- **WebSocket Testing** - Interact with real-time communication
- **Precision Scrolling** - Test complex scrolling scenarios

## 💡 Learning Tips

1. **Start with NetworkTests.swift** - Shows basic stubbing and monitoring
2. **Explore StubTests.swift** - Demonstrates advanced response scenarios
3. **Check CoreLocationTests.swift** - Learn location-based testing
4. **Review test setup methods** - See how to configure launch options

## 🎯 Next Steps

After exploring the example project:

1. **Copy patterns** you find useful to your own tests
2. **Experiment** with different configurations
3. **Refer back** to the [Usage Guide](./Usage.md) for detailed API documentation
4. **Check out** the [Setup Guide](./Setup.md) for integration instructions

---

💡 **Pro Tip**: The example project is an excellent reference implementation. Don't hesitate to use it as a starting point for your own UI testing setup!
