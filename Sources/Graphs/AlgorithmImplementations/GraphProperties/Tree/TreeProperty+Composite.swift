extension TreePropertyAlgorithm {
    /// Creates a composite tree property algorithm using separate connected and cyclic algorithms.
    ///
    /// - Parameters:
    ///   - connectedAlgorithm: The connected property algorithm to use
    ///   - cyclicAlgorithm: The cyclic property algorithm to use
    /// - Returns: A new composite tree property algorithm
    @inlinable
    public static func composite<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>(
        connectedAlgorithm: some ConnectedPropertyAlgorithm<Graph>,
        cyclicAlgorithm: some CyclicPropertyAlgorithm<Graph>
    ) -> Self where Self == CompositeTreePropertyAlgorithm<Graph> {
        .init(
            connectedAlgorithm: connectedAlgorithm,
            cyclicAlgorithm: cyclicAlgorithm
        )
    }
    
    /// Creates a DFS-based composite tree property algorithm.
    ///
    /// - Returns: A new DFS-based composite tree property algorithm
    @inlinable
    public static func dfs<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>() -> Self where Self == CompositeTreePropertyAlgorithm<Graph> {
        .composite(
            connectedAlgorithm: .dfs(),
            cyclicAlgorithm: .dfs()
        )
    }
    
    /// Creates a BFS-based composite tree property algorithm.
    ///
    /// - Returns: A new BFS-based composite tree property algorithm
    @inlinable
    public static func bfs<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>() -> Self where Self == CompositeTreePropertyAlgorithm<Graph> {
        .composite(
            connectedAlgorithm: .bfs(),
            cyclicAlgorithm: .dfs()
        )
    }
}

extension CompositeTreePropertyAlgorithm: TreePropertyAlgorithm {}
