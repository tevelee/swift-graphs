import Foundation

/// A protocol for maximum flow algorithms
protocol MaxFlowAlgorithm<Graph, Flow> {
    associatedtype Graph: IncidenceGraph & EdgePropertyGraph & EdgeListGraph & VertexListGraph where Graph.VertexDescriptor: Hashable, Graph.EdgeDescriptor: Hashable
    associatedtype Flow: AdditiveArithmetic & Comparable & FloatingPoint
    associatedtype Visitor
    
    /// Computes the maximum flow from source to sink
    /// - Parameters:
    ///   - source: The source vertex
    ///   - sink: The sink vertex
    ///   - graph: The flow network graph
    ///   - visitor: Optional visitor for algorithm events
    /// - Returns: The maximum flow result
    func maximumFlow(
        from source: Graph.VertexDescriptor,
        to sink: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> MaxFlowResult<Graph.VertexDescriptor, Graph.EdgeDescriptor, Flow>
}

/// Result of a maximum flow computation
struct MaxFlowResult<Vertex: Hashable, Edge: Hashable, Flow: AdditiveArithmetic & Comparable> {
    /// The maximum flow value
    let flowValue: Flow
    
    /// The flow through each edge
    let edgeFlows: [Edge: Flow]
    
    /// The residual capacity of each edge
    let residualCapacities: [Edge: Flow]
    
    /// The minimum cut edges (edges that are saturated in the maximum flow)
    let minCutEdges: [Edge]
    
    /// The source side vertices of the minimum cut
    let sourceSideVertices: Set<Vertex>
    
    /// The sink side vertices of the minimum cut
    let sinkSideVertices: Set<Vertex>
    
    init(
        flowValue: Flow,
        edgeFlows: [Edge: Flow],
        residualCapacities: [Edge: Flow],
        minCutEdges: [Edge],
        sourceSideVertices: Set<Vertex>,
        sinkSideVertices: Set<Vertex>
    ) {
        self.flowValue = flowValue
        self.edgeFlows = edgeFlows
        self.residualCapacities = residualCapacities
        self.minCutEdges = minCutEdges
        self.sourceSideVertices = sourceSideVertices
        self.sinkSideVertices = sinkSideVertices
    }
    
    /// Get the flow through a specific edge
    func flow(through edge: Edge) -> Flow {
        edgeFlows[edge] ?? .zero
    }
    
    /// Get the residual capacity of a specific edge
    func residualCapacity(of edge: Edge) -> Flow {
        residualCapacities[edge] ?? .zero
    }
    
    /// Check if an edge is part of the minimum cut
    func isMinCutEdge(_ edge: Edge) -> Bool {
        minCutEdges.contains(edge)
    }
}

extension VisitorWrapper: MaxFlowAlgorithm where Base: MaxFlowAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    typealias Graph = Base.Graph
    typealias Flow = Base.Flow
    
    func maximumFlow(
        from source: Base.Graph.VertexDescriptor,
        to sink: Base.Graph.VertexDescriptor,
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> MaxFlowResult<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor, Base.Flow> {
        base.maximumFlow(from: source, to: sink, in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

extension IncidenceGraph where Self: EdgePropertyGraph {
    func maximumFlow<Flow: AdditiveArithmetic & Comparable>(
        from source: VertexDescriptor,
        to sink: VertexDescriptor,
        using algorithm: some MaxFlowAlgorithm<Self, Flow>
    ) -> MaxFlowResult<VertexDescriptor, EdgeDescriptor, Flow> {
        algorithm.maximumFlow(from: source, to: sink, in: self, visitor: nil)
    }
}
