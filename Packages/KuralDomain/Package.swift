// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "KuralDomain",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "KuralDomain",
            targets: ["KuralDomain"]
        )
    ],
    targets: [
        .target(
            name: "KuralDomain",
            path: "Sources"
        )
    ]
)
