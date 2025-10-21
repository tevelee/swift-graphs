/// A protocol for maximum flow algorithms.
public protocol MaxFlowAlgorithm<Graph, Flow> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & EdgePropertyGraph & EdgeListGraph & VertexListGraph where Graph.VertexDescriptor: Hashable, Graph.EdgeDescriptor: Hashable
    /// The flow type for edge capacities and flows.
    associatedtype Flow: AdditiveArithmetic & Comparable & FloatingPoint
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Computes the maximum flow from source to sink.
    ///
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

/// Result of a maximum flow computation.
public struct MaxFlowResult<Vertex: Hashable, Edge: Hashable, Flow: AdditiveArithmetic & Comparable> {
    /// The maximum flow value.
    public let flowValue: Flow
    
    /// The flow through each edge.
    public let edgeFlows: [Edge: Flow]
    
    /// The residual capacity of each edge.
    public let residualCapacities: [Edge: Flow]
    
    /// The minimum cut edges (edges that are saturated in the maximum flow).
    public let minCutEdges: [Edge]
    
    /// The source side vertices of the minimum cut.
    public let sourceSideVertices: Set<Vertex>
    
    /// The sink side vertices of the minimum cut.
    public let sinkSideVertices: Set<Vertex>
    
    /// Creates a new maximum flow result.
    ///
    /// - Parameters:
    ///   - flowValue: The maximum flow value
    ///   - edgeFlows: The flow through each edge
    ///   - residualCapacities: The residual capacity of each edge
    ///   - minCutEdges: The minimum cut edges
    ///   - sourceSideVertices: The source side vertices of the minimum cut
    ///   - sinkSideVertices: The sink side vertices of the minimum cut
    @inlinable
    public init(
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
    
    /// Get the flow through a specific edge.
    ///
    /// - Parameter edge: The edge to get the flow for.
    /// - Returns: The flow through the edge.
    @inlinable
    public func flow(through edge: Edge) -> Flow {
        edgeFlows[edge] ?? .zero
    }
    
    /// Get the residual capacity of a specific edge.
    ///
    /// - Parameter edge: The edge to get the residual capacity for.
    /// - Returns: The residual capacity of the edge.
    @inlinable
    public func residualCapacity(of edge: Edge) -> Flow {
        residualCapacities[edge] ?? .zero
    }
    
    /// Check if an edge is part of the minimum cut.
    ///
    /// - Parameter edge: The edge to check.
    /// - Returns: True if the edge is part of the minimum cut.
    @inlinable
    public func isMinCutEdge(_ edge: Edge) -> Bool {
        minCutEdges.contains(edge)
    }
}

extension VisitorWrapper: MaxFlowAlgorithm where Base: MaxFlowAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    public typealias Flow = Base.Flow
    
    @inlinable
    public func maximumFlow(
        from source: Base.Graph.VertexDescriptor,
        to sink: Base.Graph.VertexDescriptor,
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> MaxFlowResult<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor, Base.Flow> {
        base.maximumFlow(from: source, to: sink, in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

extension IncidenceGraph where Self: EdgePropertyGraph {
    /// Computes the maximum flow using the specified algorithm.
    ///
    /// - Parameters:
    ///   - source: The source vertex
    ///   - sink: The sink vertex
    ///   - algorithm: The maximum flow algorithm to use
    /// - Returns: The maximum flow result
    @inlinable
    public func maximumFlow<Flow: AdditiveArithmetic & Comparable>(
        from source: VertexDescriptor,
        to sink: VertexDescriptor,
        using algorithm: some MaxFlowAlgorithm<Self, Flow>
    ) -> MaxFlowResult<VertexDescriptor, EdgeDescriptor, Flow> {
        algorithm.maximumFlow(from: source, to: sink, in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension BidirectionalGraph where Self: EdgePropertyGraph & EdgeListGraph & VertexListGraph, VertexDescriptor: Hashable, EdgeDescriptor: Hashable {
    /// Finds the maximum flow using Edmonds-Karp algorithm as the default.
    /// This is a well-known and efficient algorithm for maximum flow problems.
    ///
    /// - Parameters:
    ///   - source: The source vertex
    ///   - sink: The sink vertex
    ///   - capacity: The capacity definition for edge capacities
    /// - Returns: The maximum flow result
    @inlinable
    public func maximumFlow<Flow: AdditiveArithmetic & Comparable & FloatingPoint>(
        from source: VertexDescriptor,
        to sink: VertexDescriptor,
        capacity: CostDefinition<Self, Flow>
    ) -> MaxFlowResult<VertexDescriptor, EdgeDescriptor, Flow> {
        maximumFlow(from: source, to: sink, using: .edmondsKarp(capacityCost: capacity))
    }
}
