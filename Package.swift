// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "Table",
    products: [
        .library(
            name: "Table",
            targets: ["Table"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git",
                 branch: "main"),
        .package(url: "https://github.com/gallinapassus/DebugKit.git",
                 branch: "main"),
    ],
    targets: [
        .target(
            name: "Table",
            dependencies: ["DebugKit"]),
        .testTarget(
            name: "TableTests",
            dependencies: [
                "Table",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .testTarget(
            name: "PerfTests",
            dependencies: [
                "Table",
                //.product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
    ]
)
