extension MinimumSpanningTreeAlgorithm where Weight: AdditiveArithmetic {
    /// Creates a Prim MST algorithm.
    ///
    /// - Parameters:
    ///   - weight: The cost definition for edge weights
    ///   - startVertex: The starting vertex (optional, will use first vertex if nil)
    /// - Returns: A new Prim MST algorithm
    @inlinable
    public static func prim<Graph: IncidenceGraph & VertexListGraph, Weight>(
        weight: CostDefinition<Graph, Weight>,
        startVertex: Graph.VertexDescriptor? = nil
    ) -> Self where Self == Prim<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(edgeWeight: weight, startVertex: startVertex)
    }
}

extension Prim: MinimumSpanningTreeAlgorithm {
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
