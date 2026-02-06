// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ColorExtractor",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .executable(name: "color-extractor", targets: ["ColorExtractor"]),
        .library(name: "ColorExtractorCore", targets: ["ColorExtractorCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        // Core library - platform-agnostic color extraction logic
        .target(
            name: "ColorExtractorCore",
            dependencies: []
        ),

        // CLI executable
        .executableTarget(
            name: "ColorExtractor",
            dependencies: [
                "ColorExtractorCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),

        // Tests
        .testTarget(
            name: "ColorExtractorCoreTests",
            dependencies: ["ColorExtractorCore"]
        )
    ]
)
