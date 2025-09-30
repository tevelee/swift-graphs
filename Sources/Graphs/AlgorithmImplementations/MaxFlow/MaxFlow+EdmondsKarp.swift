import Foundation

extension MaxFlowAlgorithm {
    /// Creates an Edmonds-Karp maximum flow algorithm.
    ///
    /// - Parameter capacityCost: The capacity cost definition for edge capacities.
    /// - Returns: An Edmonds-Karp maximum flow algorithm instance.
    @inlinable
    public static func edmondsKarp<Graph, Flow>(
        capacityCost: CostDefinition<Graph, Flow>
    ) -> EdmondsKarp<Graph, Flow> where
        Graph: IncidenceGraph & EdgePropertyGraph & BidirectionalGraph & EdgeListGraph & VertexListGraph,
        Flow: AdditiveArithmetic & Comparable & Numeric & FloatingPoint,
        Graph.VertexDescriptor: Hashable,
        Graph.EdgeDescriptor: Hashable,
        Flow.Magnitude == Flow,
        Self == EdmondsKarp<Graph, Flow> {
        .init(capacityCost: capacityCost)
    }
}

extension EdmondsKarp: MaxFlowAlgorithm {}
