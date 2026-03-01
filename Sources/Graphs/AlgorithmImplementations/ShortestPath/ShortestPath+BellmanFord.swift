extension ShortestPathAlgorithm where Weight: AdditiveArithmetic {
    /// Creates a Bellman-Ford shortest path algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights.
    /// - Returns: A Bellman-Ford shortest path algorithm instance.
    @inlinable
    public static func bellmanFord<Graph: IncidenceGraph & EdgeListGraph & VertexListGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == BellmanFordShortestPath<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

extension SingleSourceShortestPathAlgorithm where Weight: AdditiveArithmetic {
    /// Creates a Bellman-Ford single-source shortest path algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights.
    /// - Returns: A Bellman-Ford shortest path algorithm instance.
    @inlinable
    public static func bellmanFord<Graph: IncidenceGraph & EdgeListGraph & VertexListGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == BellmanFordShortestPath<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

/// A Bellman-Ford shortest path algorithm implementation.
///
/// This struct wraps the core Bellman-Ford algorithm to provide both ShortestPathAlgorithm
/// and SingleSourceShortestPathAlgorithm interfaces, supporting graphs with negative edge weights.
///
/// - Complexity: O(VE) where V is the number of vertices and E is the number of edges
public struct BellmanFordShortestPath<
    Graph: IncidenceGraph & EdgeListGraph & VertexListGraph,
    Weight: AdditiveArithmetic & Comparable
>: ShortestPathAlgorithm, SingleSourceShortestPathAlgorithm where
    Graph.VertexDescriptor: Hashable
{
    /// The visitor type for observing algorithm progress.
    public typealias Visitor = BellmanFord<Graph, Weight>.Visitor

    /// The cost definition for edge weights.
    public let weight: CostDefinition<Graph, Weight>

    /// Creates a new Bellman-Ford shortest path algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights.
    @inlinable
    public init(weight: CostDefinition<Graph, Weight>) {
        self.weight = weight
    }

    /// Finds the shortest path from source to destination using Bellman-Ford.
    ///
    /// - Parameters:
    ///   - source: The source vertex
    ///   - destination: The destination vertex
    ///   - graph: The graph to search in
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: The shortest path, if one exists and no negative cycle is detected
    @inlinable
    public func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        shortestPaths(from: source, in: graph, visitor: visitor)
            .path(from: source, to: destination, in: graph)
    }

    /// Computes shortest paths from a single source to all reachable vertices using Bellman-Ford.
    ///
    /// - Parameters:
    ///   - source: The source vertex
    ///   - graph: The graph to search in
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: The result containing distances, predecessors, and negative cycle information
    @inlinable
    public func shortestPaths(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> SingleSourceShortestPaths<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
        let bellmanFord = BellmanFord(on: graph, edgeWeight: weight)
        let result = bellmanFord.shortestPathsFromSource(source, visitor: visitor)
        return SingleSourceShortestPaths(
            distances: result.distances,
            predecessors: result.predecessors,
            hasNegativeCycle: result.hasNegativeCycle
        )
    }
}

extension BellmanFordShortestPath: VisitorSupporting {}
