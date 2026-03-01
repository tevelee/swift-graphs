extension IncidenceGraph {
    /// Finds the shortest path from source until a condition is met.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - condition: A closure that determines when to stop searching
    ///   - algorithm: The shortest path algorithm to use
    /// - Returns: The shortest path to the first vertex satisfying the condition, or `nil` if none exists
    @inlinable
    public func shortestPath(
        from source: VertexDescriptor,
        until condition: @escaping (VertexDescriptor) -> Bool,
        using algorithm: some ShortestPathUntilAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.shortestPath(from: source, until: condition, in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
extension IncidenceGraph where VertexDescriptor: Hashable {
    /// Finds the shortest path from source until a condition is met using Dijkstra's algorithm as the default.
    /// This is useful for finding paths to the first vertex that satisfies a condition.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - condition: A closure that determines when to stop searching
    ///   - weight: The cost definition for edge weights
    /// - Returns: The shortest path to the first vertex satisfying the condition, or `nil` if none exists
    @inlinable
    public func shortestPath<Weight: Numeric & Comparable>(
        from source: VertexDescriptor,
        until condition: @escaping (VertexDescriptor) -> Bool,
        weight: CostDefinition<Self, Weight>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? where Weight.Magnitude == Weight {
        shortestPath(from: source, until: condition, using: .dijkstra(weight: weight))
    }
}
#endif

/// A protocol for shortest path algorithms that search until a condition is met.
///
/// These algorithms find the shortest path from a source vertex to the first vertex
/// that satisfies a given condition, rather than searching to a specific destination.
/// Since condition-based search is strictly more general than point-to-point search,
/// this protocol inherits from ``ShortestPathAlgorithm`` and provides a default
/// `from:to:` implementation that delegates to `from:until:`.
public protocol ShortestPathUntilAlgorithm<Graph>: ShortestPathAlgorithm {
    /// Finds the shortest path from source until a condition is met.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - condition: A closure that determines when to stop searching
    ///   - graph: The graph to search
    ///   - visitor: Optional visitor for algorithm events
    /// - Returns: The shortest path to the first vertex satisfying the condition, or `nil` if none exists
    func shortestPath(
        from source: Graph.VertexDescriptor,
        until condition: @escaping (Graph.VertexDescriptor) -> Bool,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}

// Default implementation: from:to: delegates to until:
extension ShortestPathUntilAlgorithm where Graph.VertexDescriptor: Equatable {
    /// Default implementation that delegates to the condition-based search.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The target vertex
    ///   - graph: The graph to search
    ///   - visitor: Optional visitor for algorithm events
    /// - Returns: The shortest path, or `nil` if no path exists
    @inlinable
    public func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        shortestPath(from: source, until: { $0 == destination }, in: graph, visitor: visitor)
    }
}

extension VisitorWrapper: ShortestPathUntilAlgorithm where Base: ShortestPathUntilAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    @inlinable
    public func shortestPath(
        from source: Base.Graph.VertexDescriptor,
        until condition: @escaping (Base.Graph.VertexDescriptor) -> Bool,
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.shortestPath(from: source, until: condition, in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
