// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "KuralModels",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "KuralModels",
            targets: ["KuralModels"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/huggingface/swift-transformers", from: "1.0.0"),
        .package(path: "../KuralDomain")
    ],
    targets: [
        .target(
            name: "KuralModels",
            dependencies: [
                .product(name: "Hub", package: "swift-transformers"),
                .product(name: "KuralDomain", package: "KuralDomain")
            ]
        ),
        .testTarget(
            name: "KuralModelsTests",
            dependencies: ["KuralModels"]
        )
    ]
)
