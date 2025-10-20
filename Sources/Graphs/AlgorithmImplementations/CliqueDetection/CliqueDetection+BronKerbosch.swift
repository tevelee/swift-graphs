/// Bron-Kerbosch clique detection algorithm implementation.
public struct BronKerboschCliqueDetectionAlgorithm<Graph: IncidenceGraph & VertexListGraph>: CliqueDetectionAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Visitor = BronKerboschCliqueDetection<Graph>.Visitor
    
    /// Creates a new Bron-Kerbosch clique detection algorithm.
    @inlinable
    public init() {}
    
    @inlinable
    public func findCliques(
        in graph: Graph,
        visitor: Visitor?
    ) -> CliqueDetectionResult<Graph.VertexDescriptor> {
        let bronKerbosch = BronKerboschCliqueDetection(on: graph)
        return bronKerbosch.findCliques(visitor: visitor)
    }
}

extension CliqueDetectionAlgorithm {
    /// Creates a Bron-Kerbosch clique detection algorithm.
    ///
    /// - Returns: A new Bron-Kerbosch algorithm
    @inlinable
    public static func bronKerbosch<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == BronKerboschCliqueDetectionAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}
