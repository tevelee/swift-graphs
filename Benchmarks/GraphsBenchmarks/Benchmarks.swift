import Benchmark

/// Entry point discovered by the package-benchmark plugin.
///
/// Each `register…()` function below registers a group of related benchmarks
/// via the `Benchmark(…)` API. Splitting registrations across files keeps each
/// algorithm family in its own source file.
let benchmarks: @Sendable () -> Void = {
    // Default configuration applied to every benchmark unless overridden.
    Benchmark.defaultConfiguration = .init(
        metrics: [
            .wallClock,
            .cpuTotal,
            .mallocCountTotal,
            .peakMemoryResident,
            .throughput
        ],
        warmupIterations: 2,
        scalingFactor: .one,
        maxDuration: .seconds(3),
        maxIterations: 100
    )

    registerShortestPathBenchmarks()
    registerAllPairsBenchmarks()
    registerTraversalBenchmarks()
    registerConnectivityBenchmarks()
    registerMSTBenchmarks()
    registerTopologicalSortBenchmarks()
    registerColoringBenchmarks()
    registerCentralityBenchmarks()
    registerStorageBenchmarks()
}
