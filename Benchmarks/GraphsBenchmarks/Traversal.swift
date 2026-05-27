import Benchmark
import OrderedCollections
import Graphs

func registerTraversalBenchmarks() {
    // MARK: BFS

    Benchmark("Traversal/BFS/sparse-10k-d8") { benchmark in
        let (graph, vertices) = makeSparseGraph(n: 10_000, avgDegree: 8)
        let source = vertices[0]
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var count = 0
            for _ in BreadthFirstSearch(on: graph, from: source) {
                count += 1
            }
            blackHole(count)
        }
    }

    Benchmark("Traversal/BFS/sparse-50k-d8") { benchmark in
        let (graph, vertices) = makeSparseGraph(n: 50_000, avgDegree: 8)
        let source = vertices[0]
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var count = 0
            for _ in BreadthFirstSearch(on: graph, from: source) {
                count += 1
            }
            blackHole(count)
        }
    }

    // MARK: DFS

    Benchmark("Traversal/DFS/sparse-10k-d8") { benchmark in
        let (graph, vertices) = makeSparseGraph(n: 10_000, avgDegree: 8)
        let source = vertices[0]
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var count = 0
            for _ in DepthFirstSearch(on: graph, from: source) {
                count += 1
            }
            blackHole(count)
        }
    }

    Benchmark("Traversal/DFS/sparse-50k-d8") { benchmark in
        let (graph, vertices) = makeSparseGraph(n: 50_000, avgDegree: 8)
        let source = vertices[0]
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var count = 0
            for _ in DepthFirstSearch(on: graph, from: source) {
                count += 1
            }
            blackHole(count)
        }
    }

    // MARK: Visitor overhead — verifying "nil visitor is zero cost"

    Benchmark("Traversal/BFS/with-visitor-10k") { benchmark in
        let (graph, vertices) = makeSparseGraph(n: 10_000, avgDegree: 8)
        let source = vertices[0]
        var observed = 0
        let visitor = BreadthFirstSearch<BenchGraph>.Visitor(
            discoverVertex: { _ in observed &+= 1 }
        )
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var count = 0
            var iterator = BreadthFirstSearch(on: graph, from: source).makeIterator(visitor: visitor)
            while iterator.next() != nil {
                count += 1
            }
            blackHole(count)
        }
        blackHole(observed)
    }
}
