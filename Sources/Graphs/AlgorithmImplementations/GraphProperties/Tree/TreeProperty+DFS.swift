extension TreePropertyAlgorithm {
    /// Creates a single-pass DFS-based tree property algorithm.
    ///
    /// - Returns: A new single-pass DFS-based tree property algorithm
    @inlinable
    public static func singlePass<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>() -> Self where Self == DFSTreePropertyAlgorithm<Graph> {
        .init()
    }
}

extension DFSTreePropertyAlgorithm: TreePropertyAlgorithm {}
