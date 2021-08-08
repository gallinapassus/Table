// swift-tools-version:5.3
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
    targets: [
        .target(
            name: "Table",
            dependencies: []),
        .target(name: "Table App",
                dependencies: ["Table"]),
        .testTarget(
            name: "TableTests",
            dependencies: ["Table"]),
    ]
)
