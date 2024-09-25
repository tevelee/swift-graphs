// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Graphs",
    products: [
        .library(
            name: "Graphs",
            targets: ["Graphs"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "Graphs",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Algorithms", package: "swift-algorithms")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GraphsTests",
            dependencies: ["Graphs"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
