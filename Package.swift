// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SBTUITestTunnel",
    products: [
        .library(
            name: "SBTUITestTunnelServer",
            targets: ["SBTUITestTunnelServer"]),
        .library(
            name: "SBTUITestTunnelClient",
            targets: ["SBTUITestTunnelClient"])
    ],
    dependencies: [
        .package(url: "https://github.com/Subito-it/GCDWebServer.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "SBTUITestTunnelServer",
            dependencies: ["GCDWebServer", "SBTUITestTunnelCommon", "SBTUITestTunnelCommonSwift"]
        ),
        .target(
            name: "SBTUITestTunnelClientCocoaPods",
            dependencies: ["SBTUITestTunnelCommon", "SBTUITestTunnelCommonSwift"],
            path: "Sources/SBTUITestTunnelClient"
        ),
        .target(
            name: "SBTUITestTunnelClient",
            dependencies: ["SBTUITestTunnelClientCocoaPods", "SBTUITestTunnelCommon", "SBTUITestTunnelCommonSwift"],
            path: "Sources/SBTUITestTunnelClientSPM"
        ),
        .target(
            name: "SBTUITestTunnelCommon",
            dependencies: ["SBTUITestTunnelCommonSwift"]
        ),
        .target(
            name: "SBTUITestTunnelCommonSwift"
        )
    ]
)
