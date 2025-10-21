extension ColoringAlgorithm where Color == Int {
    /// Creates a greedy coloring algorithm.
    ///
    /// - Returns: A greedy coloring algorithm instance.
    @inlinable
    public static func greedy<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == GreedyColoringAlgorithm<Graph, Int>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}

extension GreedyColoringAlgorithm: ColoringAlgorithm {
    @inlinable
    public func color(graph: Graph) -> GraphColoring<Graph.VertexDescriptor, Color> {
        color(graph: graph, visitor: nil)
    }
}
