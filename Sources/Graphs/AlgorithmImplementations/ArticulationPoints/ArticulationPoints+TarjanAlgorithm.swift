/// Tarjan's algorithm implementation for articulation points and bridges.
public struct TarjanArticulationPointsAlgorithm<Graph: IncidenceGraph & VertexListGraph>: ArticulationPointsAlgorithm where Graph.VertexDescriptor: Hashable, Graph.EdgeDescriptor: Hashable {
    public typealias Visitor = TarjanArticulationPoints<Graph>.Visitor

    /// Creates a new Tarjan articulation points algorithm.
    @inlinable
    public init() {}

    @inlinable
    public func articulationPoints(
        in graph: Graph,
        visitor: Visitor?
    ) -> ArticulationPointsResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        let tarjan = TarjanArticulationPoints(on: graph)
        return tarjan.articulationPoints(visitor: visitor)
    }
}

extension ArticulationPointsAlgorithm {
    /// Creates a Tarjan articulation points algorithm.
    ///
    /// - Returns: A new Tarjan articulation points algorithm
    @inlinable
    public static func tarjan<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == TarjanArticulationPointsAlgorithm<Graph>, Graph.VertexDescriptor: Hashable, Graph.EdgeDescriptor: Hashable {
        .init()
    }
}
