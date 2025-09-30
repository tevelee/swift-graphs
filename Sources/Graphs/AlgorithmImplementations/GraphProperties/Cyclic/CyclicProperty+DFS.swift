extension CyclicPropertyAlgorithm {
    /// Creates a DFS-based cyclic property algorithm.
    ///
    /// - Returns: A new DFS-based cyclic property algorithm
    @inlinable
    public static func dfs<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == DFSCyclicPropertyAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}

extension DFSCyclicPropertyAlgorithm: CyclicPropertyAlgorithm {}
