extension ConnectedPropertyAlgorithm {
    /// Creates a traversal-based connected property algorithm.
    ///
    /// - Parameters:
    ///   - algorithm: The traversal algorithm to use
    ///   - startingVertex: An optional starting vertex for traversal
    /// - Returns: A new traversal-based connected property algorithm
    @inlinable
    public static func traversing<Graph, Traversal>(
        using algorithm: Traversal,
        startingVertex: Graph.VertexDescriptor? = nil
    ) -> Self where Self == TraversalBasedConnectedPropertyAlgorithm<Graph, Traversal> {
        .init(using: algorithm) { graph in
            startingVertex ?? graph.vertices().first(where: { _ in true })
        }
    }
    
    /// Creates a DFS-based connected property algorithm.
    ///
    /// - Returns: A new DFS-based connected property algorithm
    @inlinable
    public static func dfs<Graph>() -> Self where Self == TraversalBasedConnectedPropertyAlgorithm<Graph, DFSTraversal<Graph>> {
        .traversing(using: .dfs())
    }
    
    /// Creates a BFS-based connected property algorithm.
    ///
    /// - Returns: A new BFS-based connected property algorithm
    @inlinable
    public static func bfs<Graph>() -> Self where Self == TraversalBasedConnectedPropertyAlgorithm<Graph, BFSTraversal<Graph>> {
        .traversing(using: .bfs())
    }
}

extension TraversalBasedConnectedPropertyAlgorithm: ConnectedPropertyAlgorithm where Traversal.Visitor: Composable, Traversal.Visitor.Other == Traversal.Visitor {}
