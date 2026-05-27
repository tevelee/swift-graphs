import Benchmark
import Graphs

func registerCentralityBenchmarks() {
    Benchmark("Centrality/PageRank/sparse-5k-d8") { benchmark in
        let (graph, _) = makeSparseGraph(n: 5_000, avgDegree: 8)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = graph.centrality(using: .pageRank())
            blackHole(result)
        }
    }

    // Betweenness is O(V·E) — keep small.
    Benchmark("Centrality/Betweenness/sparse-500-d8") { benchmark in
        let (graph, _) = makeSparseGraph(n: 500, avgDegree: 8)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = graph.centrality(using: .betweenness())
            blackHole(result)
        }
    }

    Benchmark("Centrality/Degree/sparse-10k-d8") { benchmark in
        let (graph, _) = makeSparseGraph(n: 10_000, avgDegree: 8)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = graph.centrality(using: .degree())
            blackHole(result)
        }
    }
}
