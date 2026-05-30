extension PlanarityCore {
    /// An unordered vertex-index pair `{a, b}` with `a < b`, used as an edge key.
    struct IndexPair: Hashable {
        let a: Int
        let b: Int
        init(_ x: Int, _ y: Int) {
            a = min(x, y)
            b = max(x, y)
        }
    }

    /// Computes the planar embedding result for `graph`: a rotation system if planar,
    /// otherwise a Kuratowski subgraph certificate.
    static func embeddingResult<Graph>(_ graph: Graph) -> PlanarEmbeddingResult<Graph.VertexDescriptor>
    where
        Graph: IncidenceGraph & VertexListGraph & EdgeListGraph,
        Graph.VertexDescriptor: Hashable
    {
        let indexed = indexed(graph)
        let engine = LeftRightPlanarity(n: indexed.vertices.count, adj: indexed.adjacency)

        if let rotation = engine.planarEmbedding() {
            var rotationSystem: [Graph.VertexDescriptor: [Graph.VertexDescriptor]] = [:]
            rotationSystem.reserveCapacity(rotation.count)
            for (index, neighbors) in rotation.enumerated() {
                rotationSystem[indexed.vertices[index]] = neighbors.map { indexed.vertices[$0] }
            }
            return .planar(PlanarEmbedding(rotationSystem: rotationSystem))
        }

        return .nonPlanar(kuratowski(indexed))
    }

    /// Whether the subgraph on `n` vertices induced by `edges` is planar.
    private static func isPlanar(vertexCount n: Int, edges: Set<IndexPair>) -> Bool {
        var adjacency = Array(repeating: [Int](), count: n)
        for edge in edges {
            adjacency[edge.a].append(edge.b)
            adjacency[edge.b].append(edge.a)
        }
        return LeftRightPlanarity(n: n, adj: adjacency).isPlanar()
    }

    /// Extracts a minimal non-planar subgraph (a K5 or K3,3 subdivision) from a graph already
    /// known to be non-planar, by greedy edge minimization: an edge is dropped only if the
    /// graph stays non-planar without it. The result is edge-minimal, hence a Kuratowski
    /// subdivision (Kuratowski's theorem).
    static func kuratowski<Vertex: Hashable>(_ indexed: IndexedGraph<Vertex>) -> KuratowskiSubgraph<Vertex> {
        let n = indexed.vertices.count
        var edges = Set<IndexPair>()
        for a in 0 ..< n {
            for b in indexed.adjacency[a] where a < b {
                edges.insert(IndexPair(a, b))
            }
        }

        var current = edges
        for edge in edges {
            var candidate = current
            candidate.remove(edge)
            if !isPlanar(vertexCount: n, edges: candidate) {
                current = candidate
            }
        }

        // Classify by branch-vertex count: 5 branch vertices => K5, 6 => K3,3.
        var degree = [Int: Int]()
        for edge in current {
            degree[edge.a, default: 0] += 1
            degree[edge.b, default: 0] += 1
        }
        let branchIndices = degree.filter { $0.value >= 3 }.map { $0.key }
        let kind: KuratowskiSubgraph<Vertex>.Kind = branchIndices.count == 5 ? .k5 : .k33

        return KuratowskiSubgraph(
            kind: kind,
            branchVertices: branchIndices.map { indexed.vertices[$0] },
            edges: current.map { [indexed.vertices[$0.a], indexed.vertices[$0.b]] }
        )
    }
}
