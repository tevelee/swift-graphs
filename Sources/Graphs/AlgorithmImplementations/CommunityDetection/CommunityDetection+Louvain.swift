#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
/// Louvain community detection algorithm implementation.
public struct LouvainCommunityDetectionAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>: CommunityDetectionAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Visitor = LouvainCommunityDetection<Graph>.Visitor
    
    /// The resolution parameter for modularity optimization.
    public let resolution: Double
    
    /// Creates a new Louvain community detection algorithm.
    ///
    /// - Parameter resolution: Resolution parameter for modularity optimization
    @inlinable
    public init(resolution: Double = 1.0) {
        self.resolution = resolution
    }
    
    @inlinable
    public func detectCommunities(
        in graph: Graph,
        visitor: Visitor?
    ) -> CommunityDetectionResult<Graph.VertexDescriptor> {
        let louvain = LouvainCommunityDetection(on: graph, resolution: resolution)
        return louvain.detectCommunities(visitor: visitor)
    }
}

extension CommunityDetectionAlgorithm {
    /// Creates a Louvain community detection algorithm.
    ///
    /// - Parameter resolution: Resolution parameter for modularity optimization (default: 1.0)
    /// - Returns: A new Louvain algorithm
    @inlinable
    public static func louvain<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>(resolution: Double = 1.0) -> Self where Self == LouvainCommunityDetectionAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init(resolution: resolution)
    }
}
#endif
