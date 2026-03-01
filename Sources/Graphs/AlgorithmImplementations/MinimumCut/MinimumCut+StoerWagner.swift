#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
extension MinimumCutAlgorithm where Weight: Numeric {
    /// Creates a Stoer-Wagner minimum cut algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights
    /// - Returns: A new Stoer-Wagner minimum cut algorithm
    @inlinable
    public static func stoerWagner<Graph: EdgeListGraph & IncidenceGraph & VertexListGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == StoerWagner<Graph, Weight>, Graph.VertexDescriptor: Hashable, Graph.EdgeDescriptor: Hashable {
        .init(edgeWeight: weight)
    }
}

extension StoerWagner: MinimumCutAlgorithm {
    @inlinable
    public func minimumCut(in graph: Graph, visitor: Visitor?) -> MinimumCutResult<Vertex, Edge, Weight>? {
        minimumCut(on: graph, visitor: visitor)
    }
}
#endif
