import Benchmark
import Graphs

func registerShortestPathBenchmarks() {
    // MARK: Dijkstra

    Benchmark("ShortestPath/Dijkstra/sparse-1k-d8") { benchmark in
        let (graph, vertices) = makeSparseGraph(n: 1_000, avgDegree: 8)
        let source = vertices[0]
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var last: Dijkstra<BenchGraph, Double>.Result?
            for r in Dijkstra(on: graph, from: source, edgeWeight: .property(\.weight)) {
                last = r
            }
            blackHole(last)
        }
    }

    Benchmark("ShortestPath/Dijkstra/sparse-10k-d8") { benchmark in
        let (graph, vertices) = makeSparseGraph(n: 10_000, avgDegree: 8)
        let source = vertices[0]
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var last: Dijkstra<BenchGraph, Double>.Result?
            for r in Dijkstra(on: graph, from: source, edgeWeight: .property(\.weight)) {
                last = r
            }
            blackHole(last)
        }
    }

    Benchmark("ShortestPath/Dijkstra/dense-500-d50") { benchmark in
        let (graph, vertices) = makeSparseGraph(n: 500, avgDegree: 50)
        let source = vertices[0]
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var last: Dijkstra<BenchGraph, Double>.Result?
            for r in Dijkstra(on: graph, from: source, edgeWeight: .property(\.weight)) {
                last = r
            }
            blackHole(last)
        }
    }

    // MARK: Single-pair Dijkstra (via the high-level facade)

    Benchmark("ShortestPath/Dijkstra/single-pair-10k") { benchmark in
        let (graph, vertices) = makeSparseGraph(n: 10_000, avgDegree: 8)
        let source = vertices[0]
        let target = vertices[vertices.count - 1]
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let path = graph.shortestPath(from: source, to: target, using: .dijkstra(weight: .property(\.weight)))
            blackHole(path)
        }
    }

    // MARK: Bidirectional Dijkstra

    Benchmark("ShortestPath/BidirectionalDijkstra/sparse-10k-d8") { benchmark in
        let (graph, vertices) = makeSparseGraph(n: 10_000, avgDegree: 8)
        let source = vertices[0]
        let target = vertices[vertices.count - 1]
        let weight: CostDefinition<BenchGraph, Double> = .property(\.weight)
        let algorithm: BidirectionalDijkstraShortestPath<BenchGraph, Double> = .bidirectionalDijkstra(weight: weight)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let path = graph.shortestPath(from: source, to: target, using: algorithm)
            blackHole(path)
        }
    }

    // MARK: Bellman-Ford (O(V·E) — keep small)

    Benchmark("ShortestPath/BellmanFord/sparse-500-d8") { benchmark in
        let (graph, vertices) = makeSparseGraph(n: 500, avgDegree: 8)
        let source = vertices[0]
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = graph.shortestPaths(
                from: source,
                using: .bellmanFord(weight: .property(\.weight))
            )
            blackHole(result)
        }
    }

    // MARK: SPFA

    Benchmark("ShortestPath/SPFA/sparse-1k-d8") { benchmark in
        let (graph, vertices) = makeSparseGraph(n: 1_000, avgDegree: 8)
        let source = vertices[0]
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = graph.shortestPaths(from: source, using: .spfa(weight: .property(\.weight)))
            blackHole(result)
        }
    }
}
