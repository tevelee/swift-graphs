#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
extension EulerianPathAlgorithm {
    /// Creates a Hierholzer algorithm for finding Eulerian paths.
    ///
    /// - Returns: A Hierholzer algorithm instance.
    @inlinable
    public static func hierholzer<Graph>() -> Self where Self == Hierholzer<Graph> {
        .init()
    }
}

extension Hierholzer: EulerianPathAlgorithm {
    @inlinable
    public func eulerianPath(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        eulerianPath(in: graph, visitor: nil)
    }
}
#endif
