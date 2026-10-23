// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SBTUITestTunnel",
    platforms: [.iOS(.v12), .tvOS(.v12)],
    products: [
        .library(
            name: "SBTUITestTunnelServer",
            targets: ["SBTUITestTunnelServer"]
        ),
        .library(
            name: "SBTUITestTunnelClient",
            targets: ["SBTUITestTunnelClient"]
        ),
    ],
    targets: [
        .target(
            name: "SBTUITestTunnelServer",
            dependencies: ["SBTUITestTunnelCommon", "SBTUITestTunnelCommonSwift"],
            cSettings: [
                .define("SPM", to: "YES"),
                .headerSearchPath("GCDWebServer/Core"),
                .headerSearchPath("GCDWebServer/Requests"),
                .headerSearchPath("GCDWebServer/Responses"),
            ],
            linkerSettings: [
                .linkedLibrary("z"),
            ]
        ),
        .target(
            name: "SBTUITestTunnelClientObjC",
            dependencies: ["SBTUITestTunnelCommon"],
            path: "Sources/SBTUITestTunnelClient",
            cSettings: [.define("SPM", to: "YES")]
        ),
        .target(
            name: "SBTUITestTunnelClient",
            dependencies: ["SBTUITestTunnelClientObjC", "SBTUITestTunnelCommon", "SBTUITestTunnelCommonSwift"],
            path: "Sources/SBTUITestTunnelClientSPM",
            cSettings: [.define("SPM", to: "YES")]
        ),
        .target(
            name: "SBTUITestTunnelCommon",
            exclude: ["DetoxIPC/Info.plist", "DetoxIPC/DetoxIPC.pch", "DetoxIPC/DTXObjectiveCHelpers/LICENSE", "DetoxIPC/DTXObjectiveCHelpers/README.md"],
            cSettings: [
                .define("SPM", to: "YES"),
                .headerSearchPath("DetoxIPC"),
                .headerSearchPath("DetoxIPC/Apple"),
                .headerSearchPath("DetoxIPC/DTXObjectiveCHelpers"),
            ],
            linkerSettings: [
                .linkedLibrary("z"),
            ]
        ),
        .target(
            name: "SBTUITestTunnelCommonSwift",
            dependencies: ["SBTUITestTunnelCommon"]
        ),
    ]
)
