// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "KuralStorage",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "KuralStorage",
            targets: ["KuralStorage"]
        )
    ],
    dependencies: [
        .package(path: "../KuralDomain")
    ],
    targets: [
        .target(
            name: "KuralStorage",
            dependencies: [
                "KuralDomain"
            ]
        )
    ]
)
