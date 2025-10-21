extension MaxFlowAlgorithm {
    /// Creates a Dinic's maximum flow algorithm.
    ///
    /// - Parameter capacityCost: The capacity cost definition for edge capacities.
    /// - Returns: A Dinic's maximum flow algorithm instance.
    @inlinable
    public static func dinic<Graph, Flow>(
        capacityCost: CostDefinition<Graph, Flow>
    ) -> Dinic<Graph, Flow> where
        Graph: IncidenceGraph & EdgePropertyGraph & BidirectionalGraph & EdgeListGraph & VertexListGraph,
        Flow: AdditiveArithmetic & Comparable & Numeric & FloatingPoint,
        Graph.VertexDescriptor: Hashable,
        Graph.EdgeDescriptor: Hashable,
        Flow.Magnitude == Flow,
        Self == Dinic<Graph, Flow> {
        .init(capacityCost: capacityCost)
    }
}

extension Dinic: MaxFlowAlgorithm {}
