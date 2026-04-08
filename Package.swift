// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Colormaton",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .executable(name: "colormaton", targets: ["ColormatonCLI"]),
        .library(name: "Colormaton", targets: ["Colormaton"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        // Core library - platform-agnostic color extraction logic
        .target(
            name: "Colormaton",
            dependencies: []
        ),

        // CLI executable
        .executableTarget(
            name: "ColormatonCLI",
            dependencies: [
                "Colormaton",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),

        // Tests
        .testTarget(
            name: "ColormatonTests",
            dependencies: ["Colormaton"]
        )
    ]
)
