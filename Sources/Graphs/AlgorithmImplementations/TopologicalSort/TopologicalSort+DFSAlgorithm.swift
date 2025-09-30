extension TopologicalSortAlgorithm {
    /// Creates a DFS-based topological sort algorithm.
    ///
    /// - Returns: A DFS topological sort algorithm instance.
    @inlinable
    public static func dfs<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == DFSTopologicalSort<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}
