import Benchmark
import Graphs

func registerAllPairsBenchmarks() {
    // Floyd-Warshall is O(V³); keep V modest.
    Benchmark("AllPairs/FloydWarshall/dense-200") { benchmark in
        let (graph, _) = makeSparseGraph(n: 200, avgDegree: 20)
        let weight: CostDefinition<BenchGraph, Double> = .property(\.weight)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = graph.shortestPathsForAllPairs(using: .floydWarshall(weight: weight))
            blackHole(result)
        }
    }

    // Johnson is O(V·E·log V) on sparse graphs — better than Floyd-Warshall once V is large.
    Benchmark("AllPairs/Johnson/sparse-500-d8") { benchmark in
        let (graph, _) = makeSparseGraph(n: 500, avgDegree: 8)
        let weight: CostDefinition<BenchGraph, Double> = .property(\.weight)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: weight))
            blackHole(result)
        }
    }
}
