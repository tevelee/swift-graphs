#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
/// Tarjan's algorithm implementation for strongly connected components.
public struct TarjanStronglyConnectedComponentsAlgorithm<Graph: IncidenceGraph & VertexListGraph>: StronglyConnectedComponentsAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Visitor = Tarjan<Graph>.Visitor
    
    /// Creates a new Tarjan SCC algorithm.
    @inlinable
    public init() {}
    
    @inlinable
    public func stronglyConnectedComponents(
        in graph: Graph,
        visitor: Visitor?
    ) -> StronglyConnectedComponentsResult<Graph.VertexDescriptor> {
        let tarjan = Tarjan(on: graph)
        return tarjan.stronglyConnectedComponents(visitor: visitor)
    }
}

extension StronglyConnectedComponentsAlgorithm {
    /// Creates a Tarjan SCC algorithm.
    ///
    /// - Returns: A new Tarjan SCC algorithm
    @inlinable
    public static func tarjan<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == TarjanStronglyConnectedComponentsAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}
#endif
