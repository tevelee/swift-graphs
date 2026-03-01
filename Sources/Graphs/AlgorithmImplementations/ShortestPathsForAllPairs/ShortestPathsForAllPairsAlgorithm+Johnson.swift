#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
extension ShortestPathsForAllPairsAlgorithm {
    /// Creates a Johnson algorithm for computing all-pairs shortest paths.
    ///
    /// - Parameter edgeWeight: The cost definition for edge weights.
    /// - Returns: A Johnson algorithm instance.
    @inlinable
    public static func johnson<Graph: IncidenceGraph & VertexListGraph, Weight: AdditiveArithmetic & Comparable>(
        edgeWeight: CostDefinition<Graph, Weight>
    ) -> Johnson<Graph, Weight> where Self == Johnson<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        Johnson(edgeWeight: edgeWeight)
    }
}
#endif
