// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LiveViewNativeRealityKit",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LiveViewNativeRealityKit",
            targets: ["LiveViewNativeRealityKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/liveview-native/liveview-client-swiftui", branch: "observe-children-id")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LiveViewNativeRealityKit",
            dependencies: [
                .product(name: "LiveViewNative", package: "liveview-client-swiftui")
            ]
        ),
        .testTarget(
            name: "LiveViewNativeRealityKitTests",
            dependencies: ["LiveViewNativeRealityKit"]),
    ]
)
