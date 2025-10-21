extension ColoringAlgorithm where Color == Int {
    /// Creates a DSatur coloring algorithm.
    ///
    /// - Returns: A DSatur coloring algorithm instance.
    @inlinable
    public static func dsatur<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == DSaturColoringAlgorithm<Graph, Int>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}

extension DSaturColoringAlgorithm: ColoringAlgorithm {
    @inlinable
    public func color(graph: Graph) -> GraphColoring<Graph.VertexDescriptor, Color> {
        color(graph: graph, visitor: nil)
    }
}
