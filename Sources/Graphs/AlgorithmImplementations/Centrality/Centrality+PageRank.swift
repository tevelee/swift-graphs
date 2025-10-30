extension CentralityAlgorithm {
    /// Creates a PageRank centrality algorithm.
    ///
    /// PageRank measures the importance of vertices based on the structure of incoming links.
    /// It's particularly useful for directed graphs like web graphs.
    ///
    /// - Parameters:
    ///   - dampingFactor: The damping factor (default: 0.85)
    ///   - maxIterations: Maximum number of iterations (default: 100)
    ///   - tolerance: Convergence threshold (default: 1e-6)
    /// - Returns: A new PageRank algorithm
    @inlinable
    public static func pageRank<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph>(
        dampingFactor: Double = 0.85,
        maxIterations: Int = 100,
        tolerance: Double = 1e-6
    ) -> Self where Self == PageRankCentralityAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init(dampingFactor: dampingFactor, maxIterations: maxIterations, tolerance: tolerance)
    }
}

