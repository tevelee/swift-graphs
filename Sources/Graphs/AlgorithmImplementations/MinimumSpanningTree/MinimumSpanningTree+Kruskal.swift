extension MinimumSpanningTreeAlgorithm where Weight: AdditiveArithmetic {
    /// Creates a Kruskal MST algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights
    /// - Returns: A new Kruskal MST algorithm
    @inlinable
    public static func kruskal<Graph: EdgeListGraph & IncidenceGraph  & VertexListGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == Kruskal<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(edgeWeight: weight)
    }
}

extension Kruskal: MinimumSpanningTreeAlgorithm {
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
