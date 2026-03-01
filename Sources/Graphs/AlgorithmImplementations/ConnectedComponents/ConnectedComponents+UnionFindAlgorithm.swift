#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
/// Union-Find based connected components algorithm implementation.
public struct UnionFindConnectedComponentsAlgorithm<Graph: IncidenceGraph & VertexListGraph>: ConnectedComponentsAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Visitor = UnionFindConnectedComponents<Graph>.Visitor
    
    /// Creates a new Union-Find connected components algorithm.
    @inlinable
    public init() {}
    
    @inlinable
    public func connectedComponents(
        in graph: Graph,
        visitor: Visitor?
    ) -> ConnectedComponentsResult<Graph.VertexDescriptor> {
        let unionFind = UnionFindConnectedComponents(on: graph)
        return unionFind.connectedComponents(visitor: visitor)
    }
}

extension ConnectedComponentsAlgorithm {
    /// Creates a Union-Find connected components algorithm.
    ///
    /// - Returns: A new Union-Find connected components algorithm
    @inlinable
    public static func unionFind<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == UnionFindConnectedComponentsAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}
#endif
