// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Harbor",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(name: "harbor", targets: ["Harbor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.1"),
        .package(url: "https://github.com/vapor/console-kit.git", from: "4.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "Harbor",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ConsoleKit", package: "console-kit"),
            ],
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "Harbor-Tests",
            dependencies: ["Harbor"]
        ),
    ]
)

