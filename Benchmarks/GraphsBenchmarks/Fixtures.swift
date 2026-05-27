import Graphs

// MARK: - Edge weight property

enum EdgeWeight: EdgeProperty {
    static let defaultValue: Double = 0
}

extension EdgeProperties {
    var weight: Double {
        get { self[EdgeWeight.self] }
        set { self[EdgeWeight.self] = newValue }
    }
}

// MARK: - Deterministic PRNG (SplitMix64)

/// Reproducible PRNG so benchmark fixtures are identical across runs and
/// machines; lets baseline diffs reflect real performance changes only.
struct SplitMix64 {
    var state: UInt64

    init(seed: UInt64 = 0xDEAD_BEEF_CAFE_F00D) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z &>> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z &>> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z &>> 31)
    }

    mutating func next(upperBound: Int) -> Int {
        Int(next() % UInt64(upperBound))
    }

    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        let unit = Double(next() >> 11) / Double(1 << 53)
        return range.lowerBound + (range.upperBound - range.lowerBound) * unit
    }
}

// MARK: - Default graph type

typealias BenchGraph = AdjacencyList<
    OrderedVertexStorage,
    CacheInOutEdges<OrderedEdgeStorage<OrderedVertexStorage.Vertex>>,
    DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
    DictionaryPropertyMap<LinearOrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
>

typealias BenchVertex = BenchGraph.VertexDescriptor

// MARK: - Graph generators

/// A random sparse weighted directed graph with `n` vertices and ~`n * avgDegree / 2` edges.
/// Weights drawn from `[0.1, 100.0)`. Reproducible for a given seed.
func makeSparseGraph(n: Int, avgDegree: Int, seed: UInt64 = 42) -> (BenchGraph, [BenchVertex]) {
    var graph = BenchGraph()
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

/// A directed acyclic graph: edges only go from lower-indexed to higher-indexed vertices.
/// Useful for topological-sort, DAG-shortest-path, and DFS benchmarks.
func makeDAG(n: Int, avgDegree: Int, seed: UInt64 = 42) -> (BenchGraph, [BenchVertex]) {
    var graph = BenchGraph()
    var rng = SplitMix64(seed: seed)
    let vertices = (0..<n).map { _ in graph.addVertex() }
    let targetEdges = (n * avgDegree) / 2
    var added = 0
    var attempts = 0
    while added < targetEdges && attempts < targetEdges * 4 {
        attempts += 1
        let s = rng.next(upperBound: n - 1)
        let maxSpan = min(n - s - 1, 64)
        guard maxSpan > 0 else { continue }
        let span = max(1, rng.next(upperBound: maxSpan))
        let t = s + span
        if t >= n { continue }
        let w = rng.nextDouble(in: 0.1...100.0)
        _ = graph.addEdge(from: vertices[s], to: vertices[t]) { $0.weight = w }
        added += 1
    }
    return (graph, vertices)
}

/// An undirected sparse graph (each edge inserted in both directions). Useful for MST,
/// connected-components, and coloring benchmarks where direction would distort results.
func makeUndirectedSparseGraph(n: Int, avgDegree: Int, seed: UInt64 = 42) -> (BenchGraph, [BenchVertex]) {
    var graph = BenchGraph()
    var rng = SplitMix64(seed: seed)
    let vertices = (0..<n).map { _ in graph.addVertex() }
    let edgeCount = (n * avgDegree) / 4 // /4 because we add each undirected edge twice
    for _ in 0..<edgeCount {
        let s = rng.next(upperBound: n)
        let t = rng.next(upperBound: n)
        guard s != t else { continue }
        let w = rng.nextDouble(in: 0.1...100.0)
        _ = graph.addEdge(from: vertices[s], to: vertices[t]) { $0.weight = w }
        _ = graph.addEdge(from: vertices[t], to: vertices[s]) { $0.weight = w }
    }
    return (graph, vertices)
}
