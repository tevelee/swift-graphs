// swift-tools-version: 6.2
//
// Standalone benchmark package for swift-graphs.
//
// Kept separate from the main Package.swift so the library's wide platform
// support (macOS 10.15+) is not constrained by benchmark's macOS 13+
// minimum, and so that adding/updating the benchmark dependency never affects
// library consumers.
//
// Run from the repo root:
//
//     swift package --package-path Benchmarks benchmark
//     swift package --package-path Benchmarks benchmark --filter Dijkstra
//
// Or from inside this directory:
//
//     swift package benchmark
//
// jemalloc is required for memory metrics; see README.md.

import PackageDescription

let package = Package(
    name: "GraphsBenchmarks",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // Local library — enable every algorithm trait so the suite can
        // benchmark across all algorithm families.
        .package(
            name: "swift-graphs",
            path: "..",
            traits: [
                "Pathfinding",
                "Connectivity",
                "Optimization",
                "Analysis",
                "Advanced",
                "Generation",
                "Serialization",
                "GridGraph",
                "BipartiteGraph",
                "SpecializedStorage"
            ]
        ),
        .package(url: "https://github.com/ordo-one/benchmark.git", from: "1.4.0")
    ],
    targets: [
        .executableTarget(
            name: "GraphsBenchmarks",
            dependencies: [
                .product(name: "Graphs", package: "swift-graphs"),
                .product(name: "Benchmark", package: "benchmark")
            ],
            path: "GraphsBenchmarks",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "benchmark")
            ]
        )
    ]
)
