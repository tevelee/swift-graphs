#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
extension CentralityAlgorithm {
    /// Creates a closeness centrality algorithm.
    ///
    /// Closeness centrality measures how close a vertex is to all other vertices.
    /// Vertices with high closeness can reach all other vertices quickly.
    ///
    /// - Returns: A new closeness centrality algorithm
    @inlinable
    public static func closeness<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == ClosenessCentralityAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}
#endif
