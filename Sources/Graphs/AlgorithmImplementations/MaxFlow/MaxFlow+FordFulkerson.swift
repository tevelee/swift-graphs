import Foundation

extension MaxFlowAlgorithm {
    static func fordFulkerson<Graph, Flow>(
        capacityCost: CostDefinition<Graph, Flow>
    ) -> FordFulkerson<Graph, Flow> where
        Graph: IncidenceGraph & EdgePropertyGraph & BidirectionalGraph & EdgeListGraph & VertexListGraph,
        Flow: AdditiveArithmetic & Comparable & Numeric & FloatingPoint,
        Graph.VertexDescriptor: Hashable,
        Graph.EdgeDescriptor: Hashable,
        Flow.Magnitude == Flow,
        Self == FordFulkerson<Graph, Flow> {
        .init(capacityCost: capacityCost)
    }
}

extension FordFulkerson: MaxFlowAlgorithm {}
