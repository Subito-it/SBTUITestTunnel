# SBTUITestTunnel

[![Version](https://img.shields.io/cocoapods/v/SBTUITestTunnel.svg?style=flat)](http://cocoadocs.org/docsets/SBTUITestTunnel)
[![License](https://img.shields.io/cocoapods/l/SBTUITestTunnel.svg?style=flat)](http://cocoadocs.org/docsets/SBTUITestTunnel)
[![Platform](https://img.shields.io/cocoapods/p/SBTUITestTunnel.svg?style=flat)](http://cocoadocs.org/docsets/SBTUITestTunnel)

## Overview

Apple introduced a new UI Testing feature starting from Xcode 7 that is, quoting Will Turner [on stage at the WWDC](https://developer.apple.com/videos/play/wwdc2015/406/), a huge expansion of the testing technology in the developer tools. The framework is easy to use and the integration with the IDE is great however there is a major problem with the way tests are launched. Testing code runs as a separate process which prevents to directly share data with the app under test making it hard to do things like dynamically inject data or stub network calls.

SBTUITestTunnel extends UI testing functionality allowing to dynamically:
* stub network calls
* interact with NSUserDefaults
* download/upload files from/to the app's sandbox
* monitor network calls
* define custom blocks of codes executed in the application target

The library consists of two separated components which communicate with each other, one to be instantiate in the application's target and the other in the testing target.

## Should I use this?

SBTUITestTunnel is intended to extend Apple's XCTest framework, not to replace it. It all boils down to a subclass of XCUIApplication which comes with additional features, so it is very easy to integrate (or at least try it out 😉) with your existing testing code.

## Documentation

- [Installation](https://github.com/Subito-it/SBTUITestTunnel/tree/master/Documentation/Installation.md): Describes how to install the library
- [Setup](https://github.com/Subito-it/SBTUITestTunnel/tree/master/Documentation/Setup.md): Describes how to integrate the library in your code
- [Usage](https://github.com/Subito-it/SBTUITestTunnel/tree/master/Documentation/Usage.md): Describes how to use the library

## Additional resources?

We made additional resources available to improve the UI Testing experience:

- [sbtuitestbrowser](https://github.com/Subito-it/sbtuitestbrowser): parse and visualize xcodebuild's test results in your web browser
- [SBTUITestTunnelHost](https://github.com/Subito-it/SBTUITestTunnelHost): access the mac host from your test target

## Thanks

Kudos to the developers of the following pods which we use in SBTUITestTunnel:

* [GCDWebServer](https://github.com/swisspol/GCDWebServer)

## Contributions

Contributions are welcome! If you have a bug to report, feel free to help out by opening a new issue or sending a pull request.

## Authors

[Tomas Camin](https://github.com/tcamin) ([@tomascamin](https://twitter.com/tomascamin))

## License

SBTUITestTunnel is available under the Apache License, Version 2.0. See the LICENSE file for more info.
