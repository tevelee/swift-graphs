#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
extension MaxFlowAlgorithm {
    /// Creates a Ford-Fulkerson maximum flow algorithm.
    ///
    /// - Parameter capacityCost: The capacity cost definition for edge capacities.
    /// - Returns: A Ford-Fulkerson maximum flow algorithm instance.
    @inlinable
    public static func fordFulkerson<Graph, Flow>(
        capacityCost: CostDefinition<Graph, Flow>
    ) -> FordFulkerson<Graph, Flow> where
        Graph: IncidenceGraph & BidirectionalGraph & EdgeListGraph & VertexListGraph,
        Flow: AdditiveArithmetic & Comparable & Numeric & FloatingPoint,
        Graph.VertexDescriptor: Hashable,
        Graph.EdgeDescriptor: Hashable,
        Flow.Magnitude == Flow,
        Self == FordFulkerson<Graph, Flow> {
        .init(capacityCost: capacityCost)
    }
}

extension FordFulkerson: MaxFlowAlgorithm {}
#endif
