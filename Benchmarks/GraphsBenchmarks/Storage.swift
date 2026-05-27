import Benchmark
import Graphs

// Compares edge-storage backends on identical workloads, so a regression in a
// particular backend shows up as a divergence rather than a uniform slowdown.

typealias CSRGraph = AdjacencyList<
    OrderedVertexStorage,
    CSREdgeStorage<OrderedVertexStorage.Vertex>,
    DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
    DictionaryPropertyMap<CSREdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
>

typealias OrderedNoCacheGraph = AdjacencyList<
    OrderedVertexStorage,
    LinearOrderedEdgeStorage<OrderedVertexStorage.Vertex>,
    DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
    DictionaryPropertyMap<LinearOrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
>

private func makeCSRGraph(n: Int, avgDegree: Int, seed: UInt64 = 42) -> (CSRGraph, [CSRGraph.VertexDescriptor]) {
    var graph = CSRGraph(edgeStore: CSREdgeStorage().cacheInOutEdges())
    var rng = SplitMix64(seed: seed)
    let vertices = (0..<n).map { _ in graph.addVertex() }
    let edgeCount = (n * avgDegree) / 2
    for _ in 0..<edgeCount {
        let s = rng.next(upperBound: n)
        let t = rng.next(upperBound: n)
        guard s != t else { continue }
        let w = rng.nextDouble(in: 0.1...100.0)
        _ = graph.addEdge(from: vertices[s], to: vertices[t]) { $0.weight = w }
    }
    return (graph, vertices)
}

private func makeOrderedNoCacheGraph(n: Int, avgDegree: Int, seed: UInt64 = 42) -> (OrderedNoCacheGraph, [OrderedNoCacheGraph.VertexDescriptor]) {
    var graph = OrderedNoCacheGraph(edgeStore: LinearOrderedEdgeStorage())
    var rng = SplitMix64(seed: seed)
    let vertices = (0..<n).map { _ in graph.addVertex() }
    let edgeCount = (n * avgDegree) / 2
    for _ in 0..<edgeCount {
        let s = rng.next(upperBound: n)
        let t = rng.next(upperBound: n)
        guard s != t else { continue }
        let w = rng.nextDouble(in: 0.1...100.0)
        _ = graph.addEdge(from: vertices[s], to: vertices[t]) { $0.weight = w }
    }
    return (graph, vertices)
}

func registerStorageBenchmarks() {
    // MARK: Dijkstra across edge-storage backends

    Benchmark("Storage/Dijkstra/Ordered+CacheInOut/10k-d8") { benchmark in
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

    Benchmark("Storage/Dijkstra/Ordered-bare/10k-d8") { benchmark in
        let (graph, vertices) = makeOrderedNoCacheGraph(n: 10_000, avgDegree: 8)
        let source = vertices[0]
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var last: Dijkstra<OrderedNoCacheGraph, Double>.Result?
            for r in Dijkstra(on: graph, from: source, edgeWeight: .property(\.weight)) {
                last = r
            }
            blackHole(last)
        }
    }

    Benchmark("Storage/Dijkstra/CSR/10k-d8") { benchmark in
        let (graph, vertices) = makeCSRGraph(n: 10_000, avgDegree: 8)
        let source = vertices[0]
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            var last: Dijkstra<CSRGraph, Double>.Result?
            for r in Dijkstra(on: graph, from: source, edgeWeight: .property(\.weight)) {
                last = r
            }
            blackHole(last)
        }
    }

    // MARK: BFS across edge-storage backends

    Benchmark("Storage/BFS/Ordered+CacheInOut/10k-d8") { benchmark in
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

    Benchmark("Storage/BFS/CSR/10k-d8") { benchmark in
        let (graph, vertices) = makeCSRGraph(n: 10_000, avgDegree: 8)
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

    // MARK: Edge insertion throughput

    Benchmark("Storage/Build/Ordered+CacheInOut/n=10k,d=8") { benchmark in
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let (graph, _) = makeSparseGraph(n: 10_000, avgDegree: 8)
            blackHole(graph)
        }
    }

    Benchmark("Storage/Build/CSR/n=10k,d=8") { benchmark in
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let (graph, _) = makeCSRGraph(n: 10_000, avgDegree: 8)
            blackHole(graph)
        }
    }
}
