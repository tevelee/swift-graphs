/// DFS-based connected components algorithm implementation.
public struct DFSConnectedComponentsAlgorithm<Graph: IncidenceGraph & VertexListGraph>: ConnectedComponentsAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Visitor = DFSConnectedComponents<Graph>.Visitor
    
    /// Creates a new DFS connected components algorithm.
    @inlinable
    public init() {}
    
    @inlinable
    public func connectedComponents(
        in graph: Graph,
        visitor: Visitor?
    ) -> ConnectedComponentsResult<Graph.VertexDescriptor> {
        let dfs = DFSConnectedComponents(on: graph)
        return dfs.connectedComponents(visitor: visitor)
    }
}

extension ConnectedComponentsAlgorithm {
    /// Creates a DFS connected components algorithm.
    ///
    /// - Returns: A new DFS connected components algorithm
    @inlinable
    public static func dfs<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == DFSConnectedComponentsAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}
