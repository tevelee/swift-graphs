extension ColoringAlgorithm where Color == Int {
    /// Creates a Welsh-Powell coloring algorithm.
    ///
    /// - Returns: A Welsh-Powell coloring algorithm instance.
    @inlinable
    public static func welshPowell<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == WelshPowellColoringAlgorithm<Graph, Int>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}

extension WelshPowellColoringAlgorithm: ColoringAlgorithm {
    @inlinable
    public func color(graph: Graph) -> GraphColoring<Graph.VertexDescriptor, Color> {
        color(graph: graph, visitor: nil)
    }
}
