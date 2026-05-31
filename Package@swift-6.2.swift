// swift-tools-version: 6.2

import Foundation
import PackageDescription

let generatingDocs = ProcessInfo.processInfo.environment["GENERATING_DOCS"] != nil

let package = Package(
    name: "Graphs",
    platforms: [
        .iOS(.v13),
        .macCatalyst(.v13),
        .macOS(.v10_15),
        .watchOS(.v6),
        .tvOS(.v13),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "Graphs",
            targets: ["Graphs"]
        )
    ],
    traits: [
        .default(enabledTraits: generatingDocs ? ["Full"] : ["Pathfinding", "Connectivity"]),
        .trait(name: "Pathfinding"),
        .trait(name: "Connectivity"),
        .trait(name: "Optimization"),
        .trait(name: "Analysis"),
        .trait(name: "Advanced"),
        .trait(name: "Generation"),
        .trait(name: "Serialization"),
        .trait(name: "GridGraph"),
        .trait(name: "BipartiteGraph"),
        .trait(name: "SpecializedStorage"),
        .trait(name: "CompleteGraph"),
        .trait(name: "Full", enabledTraits: [
            "Pathfinding",
            "Connectivity",
            "Optimization",
            "Analysis",
            "Advanced",
            "Generation",
            "Serialization",
            "GridGraph",
            "BipartiteGraph",
            "SpecializedStorage",
            "CompleteGraph",
        ]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Graphs",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Algorithms", package: "swift-algorithms"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .define("GRAPHS_USES_TRAITS"),
                .define("GRAPHS_PATHFINDING", .when(traits: ["Pathfinding"])),
                .define("GRAPHS_CONNECTIVITY", .when(traits: ["Connectivity"])),
                .define("GRAPHS_OPTIMIZATION", .when(traits: ["Optimization"])),
                .define("GRAPHS_ANALYSIS", .when(traits: ["Analysis"])),
                .define("GRAPHS_ADVANCED", .when(traits: ["Advanced"])),
                .define("GRAPHS_GENERATION", .when(traits: ["Generation"])),
                .define("GRAPHS_SERIALIZATION", .when(traits: ["Serialization"])),
                .define("GRAPHS_GRID_GRAPH", .when(traits: ["GridGraph"])),
                .define("GRAPHS_BIPARTITE_GRAPH", .when(traits: ["BipartiteGraph"])),
                .define("GRAPHS_SPECIALIZED_STORAGE", .when(traits: ["SpecializedStorage"])),
                .define("GRAPHS_COMPLETE_GRAPH", .when(traits: ["CompleteGraph"])),
            ]
        ),
        .testTarget(
            name: "GraphsTests",
            dependencies: ["Graphs"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .define("GRAPHS_USES_TRAITS"),
                .define("GRAPHS_PATHFINDING", .when(traits: ["Pathfinding"])),
                .define("GRAPHS_CONNECTIVITY", .when(traits: ["Connectivity"])),
                .define("GRAPHS_OPTIMIZATION", .when(traits: ["Optimization"])),
                .define("GRAPHS_ANALYSIS", .when(traits: ["Analysis"])),
                .define("GRAPHS_ADVANCED", .when(traits: ["Advanced"])),
                .define("GRAPHS_GENERATION", .when(traits: ["Generation"])),
                .define("GRAPHS_SERIALIZATION", .when(traits: ["Serialization"])),
                .define("GRAPHS_GRID_GRAPH", .when(traits: ["GridGraph"])),
                .define("GRAPHS_BIPARTITE_GRAPH", .when(traits: ["BipartiteGraph"])),
                .define("GRAPHS_SPECIALIZED_STORAGE", .when(traits: ["SpecializedStorage"])),
                .define("GRAPHS_COMPLETE_GRAPH", .when(traits: ["CompleteGraph"])),
            ]
        ),
    ]
)

if generatingDocs {
    package.dependencies.append(
        .package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.0.0")
    )
}
