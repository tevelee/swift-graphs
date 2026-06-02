/// A protocol for minimum cost flow algorithms.
///
/// Minimum cost flow finds a flow from source to sink that minimizes the total cost,
/// subject to edge capacities. Each edge carries both a capacity (maximum flow) and a
/// cost (per-unit-of-flow charge). The algorithm either pushes as much flow as possible
/// at minimum cost (minimum cost maximum flow), or meets a specified demand at minimum cost.
///
/// Use this when you need to:
/// - Route traffic or goods through a network as cheaply as possible
/// - Solve assignment and transportation problems
/// - Find minimum cost maximum flow
public protocol MinCostFlowAlgorithm<Graph, Value> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & EdgeListGraph & VertexListGraph
    where Graph.VertexDescriptor: Hashable, Graph.EdgeDescriptor: Hashable
    /// The numeric type used for both flow amounts and per-unit costs.
    associatedtype Value: AdditiveArithmetic & Comparable & SignedNumeric
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor

    /// Computes the minimum cost flow from source to sink.
    ///
    /// - Parameters:
    ///   - source: The source vertex.
    ///   - sink: The sink vertex.
    ///   - demand: The required flow amount, or `nil` to compute minimum cost maximum flow.
    ///   - graph: The flow network graph.
    ///   - visitor: Optional visitor for observing algorithm events.
    /// - Returns: The minimum cost flow result.
    func minimumCostFlow(
        from source: Graph.VertexDescriptor,
        to sink: Graph.VertexDescriptor,
        demand: Value?,
        in graph: Graph,
        visitor: Visitor?
    ) -> MinCostFlowResult<Graph.VertexDescriptor, Graph.EdgeDescriptor, Value>
}

/// Result of a minimum cost flow computation.
public struct MinCostFlowResult<Vertex: Hashable, Edge: Hashable, Value: AdditiveArithmetic & Comparable> {
    /// The total amount of flow achieved from source to sink.
    public let flowValue: Value

    /// The total cost of the flow (sum of flow × cost over all edges).
    public let totalCost: Value

    /// The flow assigned to each edge.
    public let edgeFlows: [Edge: Value]

    /// Whether the requested demand was fully satisfied.
    ///
    /// Always `true` when no demand was specified (minimum cost maximum flow mode).
    /// `false` when the demanded flow exceeds the maximum flow the network can carry.
    public let isFeasible: Bool

    /// Creates a new minimum cost flow result.
    @inlinable
    public init(flowValue: Value, totalCost: Value, edgeFlows: [Edge: Value], isFeasible: Bool) {
        self.flowValue = flowValue
        self.totalCost = totalCost
        self.edgeFlows = edgeFlows
        self.isFeasible = isFeasible
    }

    /// Returns the flow through a specific edge, or zero if the edge carries no flow.
    ///
    /// - Parameter edge: The edge to query.
    @inlinable
    public func flow(through edge: Edge) -> Value {
        edgeFlows[edge] ?? .zero
    }
}

extension MinCostFlowResult: Sendable where Vertex: Sendable, Edge: Sendable, Value: Sendable {}

extension VisitorWrapper: MinCostFlowAlgorithm
where
    Base: MinCostFlowAlgorithm,
    Base.Visitor == Visitor,
    Visitor: Composable,
    Visitor.Other == Visitor
{
    public typealias Graph = Base.Graph
    public typealias Value = Base.Value

    @inlinable
    public func minimumCostFlow(
        from source: Base.Graph.VertexDescriptor,
        to sink: Base.Graph.VertexDescriptor,
        demand: Base.Value?,
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> MinCostFlowResult<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor, Base.Value> {
        base.minimumCostFlow(
            from: source,
            to: sink,
            demand: demand,
            in: graph,
            visitor: self.visitor.combined(with: visitor)
        )
    }
}

extension IncidenceGraph {
    /// Computes the minimum cost flow using the specified algorithm.
    ///
    /// - Parameters:
    ///   - source: The source vertex.
    ///   - sink: The sink vertex.
    ///   - demand: The required flow amount, or `nil` for minimum cost maximum flow.
    ///   - algorithm: The minimum cost flow algorithm to use.
    /// - Returns: The minimum cost flow result.
    @inlinable
    public func minimumCostFlow<Value: AdditiveArithmetic & Comparable & SignedNumeric>(
        from source: VertexDescriptor,
        to sink: VertexDescriptor,
        demand: Value? = nil,
        using algorithm: some MinCostFlowAlgorithm<Self, Value>
    ) -> MinCostFlowResult<VertexDescriptor, EdgeDescriptor, Value> {
        algorithm.minimumCostFlow(from: source, to: sink, demand: demand, in: self, visitor: nil)
    }
}

// MARK: - Default Implementation

#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
    extension IncidenceGraph
    where Self: EdgeListGraph & VertexListGraph, VertexDescriptor: Hashable, EdgeDescriptor: Hashable {
        /// Computes the minimum cost flow using the Successive Shortest Paths algorithm.
        ///
        /// This is the default implementation. It finds minimum cost augmenting paths using
        /// SPFA and augments along them until maximum flow or the specified demand is reached.
        ///
        /// - Parameters:
        ///   - source: The source vertex.
        ///   - sink: The sink vertex.
        ///   - capacity: A definition of how to extract each edge's capacity.
        ///   - unitCost: A definition of how to extract each edge's per-unit-flow cost.
        ///   - demand: The required flow amount, or `nil` for minimum cost maximum flow.
        /// - Returns: The minimum cost flow result.
        @inlinable
        public func minimumCostFlow<Value: AdditiveArithmetic & Comparable & SignedNumeric>(
            from source: VertexDescriptor,
            to sink: VertexDescriptor,
            capacity: CostDefinition<Self, Value>,
            unitCost: CostDefinition<Self, Value>,
            demand: Value? = nil
        ) -> MinCostFlowResult<VertexDescriptor, EdgeDescriptor, Value> {
            minimumCostFlow(
                from: source,
                to: sink,
                demand: demand,
                using: .successiveShortestPaths(capacity: capacity, unitCost: unitCost)
            )
        }
    }
#endif
