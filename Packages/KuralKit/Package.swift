// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "KuralKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "KuralKit",
            targets: ["KuralKit"]
        )
    ],
    dependencies: [
        .package(path: "../KuralDomain"),
        .package(path: "../KuralEngine"),
        .package(path: "../KuralStorage"),
        .package(path: "../KuralModels")
    ],
    targets: [
        .target(
            name: "KuralKit",
            dependencies: [
                "KuralDomain",
                "KuralEngine",
                "KuralStorage",
                "KuralModels"
            ],
            path: "Sources"
        )
    ]
)
