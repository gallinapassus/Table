// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Table",
    products: [
        .library(
            name: "Table",
            targets: ["Table"]),
        .executable(name: "tableapp",
                    targets: ["Table App"])
    ],
    dependencies: [
        //.package(path: "../Combinations"),
        .package(url: "https://github.com/gallinapassus/DebugKit.git",
                 branch: "main"),
    ],
    targets: [
        .target(
            name: "Table",
            dependencies: ["DebugKit"]),
        .target(name: "Table App",
                dependencies: ["Table"]),
        .testTarget(
            name: "TableTests",
            dependencies: ["Table"/*, "Combinations"*/]),
    ]
)
