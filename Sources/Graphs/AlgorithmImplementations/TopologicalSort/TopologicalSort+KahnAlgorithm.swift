#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
extension TopologicalSortAlgorithm {
    /// Creates a Kahn topological sort algorithm.
    ///
    /// - Returns: A new Kahn topological sort algorithm
    @inlinable
    public static func kahn<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == Kahn<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}
#endif
