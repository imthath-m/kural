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
        .package(path: "../KuralKit"),
        .package(path: "../KuralDomain"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.2.0")
    ],
    targets: [
        .target(
            name: "KuralMacOS",
            dependencies: [
                "KuralKit",
                "KuralDomain",
                "KeyboardShortcuts"
            ],
            path: "Sources"
        )
    ]
)
