// swift-tools-version: 5.9

import Foundation
import PackageDescription

// swift-docc-plugin is only needed when generating documentation.
// Set GENERATING_DOCS=1 to include it (used by the docc.yml CI workflow).
var extraDependencies: [Package.Dependency] = []
if ProcessInfo.processInfo.environment["GENERATING_DOCS"] != nil {
    extraDependencies.append(
        .package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.0.0")
    )
}

let package = Package(
    name: "Graphs",
    platforms: [
        .iOS(.v13),
        .macCatalyst(.v13),
        .macOS(.v10_15),
        .watchOS(.v6),
        .tvOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "Graphs",
            targets: ["Graphs"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0"),
    ] + extraDependencies,
    targets: [
        .target(
            name: "Graphs",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Algorithms", package: "swift-algorithms")
            ]
        ),
        .testTarget(
            name: "GraphsTests",
            dependencies: ["Graphs"]
        )
    ]
)
