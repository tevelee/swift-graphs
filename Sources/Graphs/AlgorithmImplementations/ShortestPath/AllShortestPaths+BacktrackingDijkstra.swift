#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
extension AllShortestPathsUntilAlgorithm {
    /// Creates a backtracking Dijkstra algorithm for finding all shortest paths until a condition is met.
    ///
    /// This algorithm finds all paths from source to vertices that satisfy a condition and share the optimal (minimum) cost.
    /// It first runs Dijkstra to find the optimal cost, then tracks all predecessors that maintain
    /// that optimal cost, and finally backtracks to enumerate all such paths.
    ///
    /// - Parameter weight: The cost definition for edge weights
    /// - Returns: A backtracking Dijkstra algorithm instance
    @inlinable
    public static func backtrackingDijkstra<Graph: IncidenceGraph, Weight: Numeric>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where
        Self == BacktrackingDijkstraAllShortestPathsAlgorithm<Graph, Weight>,
        Weight.Magnitude == Weight,
        Graph.VertexDescriptor: Hashable
    {
        .init(weight: weight)
    }
}

extension AllShortestPathsAlgorithm {
    /// Creates a backtracking Dijkstra algorithm for finding all shortest paths.
    ///
    /// This algorithm finds all paths between two vertices that share the optimal (minimum) cost.
    /// It first runs Dijkstra to find the optimal cost, then tracks all predecessors that maintain
    /// that optimal cost, and finally backtracks to enumerate all such paths.
    ///
    /// - Parameter weight: The cost definition for edge weights
    /// - Returns: A backtracking Dijkstra algorithm instance
    @inlinable
    public static func backtrackingDijkstra<Graph: IncidenceGraph, Weight: Numeric>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where
        Self == BacktrackingDijkstraAllShortestPathsAlgorithm<Graph, Weight>,
        Weight.Magnitude == Weight,
        Graph.VertexDescriptor: Hashable
    {
        .init(weight: weight)
    }
}

/// An all shortest paths algorithm based on backtracking Dijkstra.
public struct BacktrackingDijkstraAllShortestPathsAlgorithm<
    Graph: IncidenceGraph,
    Weight: Numeric & Comparable
>: AllShortestPathsUntilAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    /// The visitor type for observing algorithm progress.
    public typealias Visitor = BacktrackingDijkstra<Graph, Weight>.Visitor

    /// The cost definition for edge weights.
    public let weight: CostDefinition<Graph, Weight>

    /// Creates a backtracking Dijkstra all shortest paths algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights
    @inlinable
    public init(weight: CostDefinition<Graph, Weight>) {
        self.weight = weight
    }

    /// Finds all shortest paths from source until a condition is met using backtracking Dijkstra.
    ///
    /// - Parameters:
    ///   - source: The source vertex
    ///   - condition: The condition that determines when to stop
    ///   - graph: The graph to search in
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: An array of all shortest paths
    @inlinable
    public func allShortestPaths(
        from source: Graph.VertexDescriptor,
        until condition: @escaping (Graph.VertexDescriptor) -> Bool,
        in graph: Graph,
        visitor: Visitor?
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>] {
        let algorithm = BacktrackingDijkstra(on: graph, edgeWeight: weight)
        let result = algorithm.findAllShortestPaths(from: source, until: condition, visitor: visitor)
        return result.paths
    }
}

extension BacktrackingDijkstraAllShortestPathsAlgorithm: VisitorSupporting {}
#endif
