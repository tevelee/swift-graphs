#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
extension MinimumSpanningTreeAlgorithm where Weight: AdditiveArithmetic {
    /// Creates a Borůvka MST algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights
    /// - Returns: A new Borůvka MST algorithm
    @inlinable
    public static func boruvka<Graph: EdgeListGraph & IncidenceGraph  & VertexListGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == Boruvka<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(edgeWeight: weight)
    }
}

extension Boruvka: MinimumSpanningTreeAlgorithm {
    @inlinable
    public func minimumSpanningTree(in graph: Graph, visitor: Visitor?) -> MinimumSpanningTree<Vertex, Edge, Weight> {
        let result = minimumSpanningTree(on: graph, visitor: visitor)
        return MinimumSpanningTree(
            edges: result.edges,
            totalWeight: result.totalWeight,
            vertices: result.vertices
        )
    }
}
#endif
