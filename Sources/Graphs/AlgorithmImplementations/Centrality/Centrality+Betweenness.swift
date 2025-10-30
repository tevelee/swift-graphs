extension CentralityAlgorithm {
    /// Creates a betweenness centrality algorithm.
    ///
    /// Betweenness centrality measures how often a vertex appears on shortest paths
    /// between other vertices. Vertices with high betweenness act as bridges or bottlenecks.
    ///
    /// - Parameter normalized: Whether to normalize values (default: true)
    /// - Returns: A new betweenness centrality algorithm
    @inlinable
    public static func betweenness<Graph: IncidenceGraph & VertexListGraph>(
        normalized: Bool = true
    ) -> Self where Self == BetweennessCentralityAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init(normalized: normalized)
    }
}

