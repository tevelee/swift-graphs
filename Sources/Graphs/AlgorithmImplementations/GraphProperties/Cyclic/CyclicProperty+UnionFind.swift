extension CyclicPropertyAlgorithm {
    /// Creates a Union-Find-based cyclic property algorithm.
    ///
    /// - Returns: A new Union-Find-based cyclic property algorithm
    @inlinable
    public static func unionFind<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>() -> Self where Self == UnionFindCyclicPropertyAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}

extension UnionFindCyclicPropertyAlgorithm: CyclicPropertyAlgorithm {}
