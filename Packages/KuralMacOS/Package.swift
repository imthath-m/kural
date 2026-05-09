// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "KuralMacOS",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "KuralMacOS",
            targets: ["KuralMacOS"]
        )
    ],
    dependencies: [
        .package(path: "../KuralKit")
    ],
    targets: [
        .target(
            name: "KuralMacOS",
            dependencies: ["KuralKit"],
            path: "Sources"
        )
    ]
)
