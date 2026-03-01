/// A protocol for algorithms that compute shortest paths from a single source to all reachable vertices.
///
/// Single-source shortest path algorithms find the shortest distances from one vertex to all others
/// in a weighted graph. Different algorithms handle different weight constraints — for example,
/// SPFA and Bellman-Ford support negative edge weights, while Dijkstra requires non-negative weights.
public protocol SingleSourceShortestPathAlgorithm<Graph, Weight> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    /// The weight type used for edge weights.
    associatedtype Weight: AdditiveArithmetic & Comparable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor

    /// Computes shortest paths from a single source vertex to all reachable vertices.
    ///
    /// - Parameters:
    ///   - source: The source vertex to compute shortest paths from.
    ///   - graph: The graph to compute shortest paths in.
    ///   - visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: The shortest paths from the source to all reachable vertices.
    func shortestPaths(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> SingleSourceShortestPaths<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight>
}

/// A result containing shortest paths from a single source vertex.
public struct SingleSourceShortestPaths<Vertex: Hashable, Edge, Weight: AdditiveArithmetic & Comparable> {
    /// The distances from the source to each vertex.
    public let distances: [Vertex: Cost<Weight>]
    /// The predecessor edges for reconstructing paths.
    public let predecessors: [Vertex: Edge?]
    /// Whether a negative cycle was detected.
    public let hasNegativeCycle: Bool

    /// Creates a new single-source shortest paths result.
    ///
    /// - Parameters:
    ///   - distances: The distances from the source to each vertex.
    ///   - predecessors: The predecessor edges for reconstructing paths.
    ///   - hasNegativeCycle: Whether a negative cycle was detected.
    @inlinable
    public init(distances: [Vertex: Cost<Weight>], predecessors: [Vertex: Edge?], hasNegativeCycle: Bool) {
        self.distances = distances
        self.predecessors = predecessors
        self.hasNegativeCycle = hasNegativeCycle
    }

    /// Gets the distance from the source to a vertex.
    ///
    /// - Parameter vertex: The destination vertex.
    /// - Returns: The distance to the vertex, or `nil` if the vertex is not in the result.
    @inlinable
    public func distance(to vertex: Vertex) -> Cost<Weight>? {
        distances[vertex]
    }

    /// Gets the shortest path from the source to a destination vertex.
    ///
    /// - Parameters:
    ///   - source: The source vertex.
    ///   - destination: The destination vertex.
    ///   - graph: The graph to reconstruct the path in.
    /// - Returns: The shortest path, or `nil` if no path exists or a negative cycle was detected.
    @inlinable
    public func path(from source: Vertex, to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> Path<Vertex, Edge>? {
        guard !hasNegativeCycle else { return nil }
        guard case .finite = distances[destination] else { return nil }

        var current = destination
        var vertices: [Vertex] = [destination]
        var edges: [Edge] = []

        while current != source {
            guard let edge = predecessors[current], let edge else { return nil }
            edges.append(edge)
            guard let predecessor = graph.source(of: edge) else { return nil }
            vertices.append(predecessor)
            current = predecessor
        }

        vertices.reverse()
        edges.reverse()

        return Path(
            source: source,
            destination: destination,
            vertices: vertices,
            edges: edges
        )
    }
}

extension SingleSourceShortestPaths: Sendable where Vertex: Sendable, Edge: Sendable, Weight: Sendable {}

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Computes shortest paths from a single source vertex using the specified algorithm.
    ///
    /// - Parameters:
    ///   - source: The source vertex to compute shortest paths from.
    ///   - algorithm: The algorithm to use for computing shortest paths.
    /// - Returns: The shortest paths from the source to all reachable vertices.
    @inlinable
    public func shortestPaths<Weight: AdditiveArithmetic & Comparable>(
        from source: VertexDescriptor,
        using algorithm: some SingleSourceShortestPathAlgorithm<Self, Weight>
    ) -> SingleSourceShortestPaths<VertexDescriptor, EdgeDescriptor, Weight> {
        algorithm.shortestPaths(from: source, in: self, visitor: nil)
    }
}

extension VisitorWrapper: SingleSourceShortestPathAlgorithm where Base: SingleSourceShortestPathAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    @inlinable
    public func shortestPaths(
        from source: Base.Graph.VertexDescriptor,
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> SingleSourceShortestPaths<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor, Base.Weight> {
        base.shortestPaths(from: source, in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
