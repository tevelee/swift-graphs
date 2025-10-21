extension ColoringAlgorithm where Color == Int {
    /// Creates a Sequential Vertex Coloring algorithm.
    ///
    /// - Parameter orderingAlgorithm: The vertex ordering algorithm to use
    /// - Returns: A new Sequential Vertex Coloring algorithm
    @inlinable
    public static func sequential<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph>(
        orderUsing orderingAlgorithm: any VertexOrderingAlgorithm<Graph>
    ) -> Self where Self == SequentialVertexColoringAlgorithm<Graph, Int>, Graph.VertexDescriptor: Hashable {
        .init(using: orderingAlgorithm)
    }
}

extension SequentialVertexColoringAlgorithm: ColoringAlgorithm {
    @inlinable
    public func color(graph: Graph) -> GraphColoring<Graph.VertexDescriptor, Color> {
        color(graph: graph, visitor: nil)
    }
}
