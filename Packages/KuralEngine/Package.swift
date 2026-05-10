// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "KuralEngine",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "KuralEngine",
            targets: ["KuralEngine"]
        )
    ],
    dependencies: [
        .package(path: "../KuralDomain")
    ],
    targets: [
        .target(
            name: "KuralEngine",
            dependencies: [
                "KuralDomain"
            ]
        )
    ]
)
