// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "bento-ios-example",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "bento-ios-example",
            targets: ["bento-ios-example"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "bento-ios-example"),
        .testTarget(
            name: "bento-ios-exampleTests",
            dependencies: ["bento-ios-example"]
        ),
    ]
)
