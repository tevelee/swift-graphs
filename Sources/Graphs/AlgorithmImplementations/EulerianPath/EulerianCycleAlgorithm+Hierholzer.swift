#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
extension EulerianCycleAlgorithm {
    /// Creates a Hierholzer algorithm for finding Eulerian cycles.
    ///
    /// - Returns: A Hierholzer algorithm instance.
    @inlinable
    public static func hierholzer<Graph>() -> Self where Self == Hierholzer<Graph> {
        .init()
    }
}

extension Hierholzer: EulerianCycleAlgorithm {
    @inlinable
    public func eulerianCycle(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        eulerianCycle(in: graph, visitor: nil)
    }
}
#endif
