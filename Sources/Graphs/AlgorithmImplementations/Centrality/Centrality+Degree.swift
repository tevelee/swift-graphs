#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
extension CentralityAlgorithm {
    /// Creates a degree centrality algorithm.
    ///
    /// Degree centrality measures the number of connections a vertex has.
    /// It's the simplest centrality measure, counting outgoing edges.
    ///
    /// - Parameter normalized: Whether to normalize values (default: true)
    /// - Returns: A new degree centrality algorithm
    @inlinable
    public static func degree<Graph: IncidenceGraph & VertexListGraph>(
        normalized: Bool = true
    ) -> Self where Self == DegreeCentralityAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init(normalized: normalized)
    }
}
#endif
