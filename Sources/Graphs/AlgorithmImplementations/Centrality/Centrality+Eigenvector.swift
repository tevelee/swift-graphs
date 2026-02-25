#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
extension CentralityAlgorithm {
    /// Creates an eigenvector centrality algorithm.
    ///
    /// Eigenvector centrality measures a vertex's importance based on the importance
    /// of its neighbors. A vertex is important if it's connected to other important vertices.
    ///
    /// - Parameters:
    ///   - maxIterations: Maximum number of iterations (default: 100)
    ///   - tolerance: Convergence threshold (default: 1e-6)
    /// - Returns: A new eigenvector centrality algorithm
    @inlinable
    public static func eigenvector<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph>(
        maxIterations: Int = 100,
        tolerance: Double = 1e-6
    ) -> Self where Self == EigenvectorCentralityAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init(maxIterations: maxIterations, tolerance: tolerance)
    }
}
#endif
