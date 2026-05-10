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
        .package(path: "../KuralDomain"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "KuralEngine",
            dependencies: [
                "KuralDomain",
                .product(name: "MLXSwiftLM", package: "mlx-swift-lm")
            ]
        ),
        .testTarget(
            name: "KuralEngineTests",
            dependencies: ["KuralEngine"]
        )
    ]
)
