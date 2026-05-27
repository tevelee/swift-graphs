import Benchmark
import Graphs

func registerColoringBenchmarks() {
    Benchmark("Coloring/Greedy/undirected-2k-d12") { benchmark in
        let (graph, _) = makeUndirectedSparseGraph(n: 2_000, avgDegree: 12)
        let algorithm: GreedyColoringAlgorithm<BenchGraph, Int> = .greedy()
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = graph.colorGraph(using: algorithm)
            blackHole(result)
        }
    }

    Benchmark("Coloring/DSatur/undirected-2k-d12") { benchmark in
        let (graph, _) = makeUndirectedSparseGraph(n: 2_000, avgDegree: 12)
        let algorithm: DSaturColoringAlgorithm<BenchGraph, Int> = .dsatur()
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = graph.colorGraph(using: algorithm)
            blackHole(result)
        }
    }
}
