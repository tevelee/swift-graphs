extension IncidenceGraph where VertexDescriptor: Equatable {
    /// Finds the shortest path between two vertices using the specified algorithm.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The target vertex
    ///   - algorithm: The shortest path algorithm to use
    /// - Returns: The shortest path, or `nil` if no path exists
    @inlinable
    public func shortestPath(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        using algorithm: some ShortestPathAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.shortestPath(from: source, to: destination, in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where VertexDescriptor: Hashable {
    /// Finds the shortest path between two vertices using Dijkstra's algorithm as the default.
    /// This is the most commonly used and efficient algorithm for non-negative edge weights.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The target vertex
    ///   - weight: The cost definition for edge weights
    /// - Returns: The shortest path, or `nil` if no path exists
    @inlinable
    public func shortestPath<Weight: Numeric & Comparable>(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        weight: CostDefinition<Self, Weight>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? where Weight.Magnitude == Weight {
        shortestPath(from: source, to: destination, using: .dijkstra(weight: weight))
    }
}

/// A protocol for shortest path algorithms.
///
/// Shortest path algorithms find the path with minimum total weight between two vertices
/// in a weighted graph. Different algorithms have different characteristics and requirements.
public protocol ShortestPathAlgorithm<Graph> {
    /// The type of graph this algorithm operates on.
    associatedtype Graph: IncidenceGraph

    /// The type of visitor used for algorithm events.
    associatedtype Visitor

    /// Finds the shortest path between two vertices.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The target vertex
    ///   - graph: The graph to search
    ///   - visitor: Optional visitor for algorithm events
    /// - Returns: The shortest path, or `nil` if no path exists
    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}

extension VisitorWrapper: ShortestPathAlgorithm where Base: ShortestPathAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph

    @inlinable
    public func shortestPath(
        from source: Base.Graph.VertexDescriptor,
        to destination: Base.Graph.VertexDescriptor,
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.shortestPath(from: source, to: destination, in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
