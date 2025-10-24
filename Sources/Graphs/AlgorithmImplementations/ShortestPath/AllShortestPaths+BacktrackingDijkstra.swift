extension AllShortestPathsUntilAlgorithm where Weight: Numeric, Weight.Magnitude == Weight {
    /// Creates a backtracking Dijkstra algorithm for finding all shortest paths until a condition is met.
    ///
    /// This algorithm finds all paths from source to vertices that satisfy a condition and share the optimal (minimum) cost.
    /// It first runs Dijkstra to find the optimal cost, then tracks all predecessors that maintain
    /// that optimal cost, and finally backtracks to enumerate all such paths.
    ///
    /// - Parameter weight: The cost definition for edge weights
    /// - Returns: A backtracking Dijkstra algorithm instance
    @inlinable
    public static func backtrackingDijkstra<Graph: IncidenceGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where 
        Self == BacktrackingDijkstraAllShortestPathsAlgorithm<Graph, Weight>,
        Graph.VertexDescriptor: Hashable
    {
        .init(weight: weight)
    }
}

extension AllShortestPathsAlgorithm where Weight: Numeric, Weight.Magnitude == Weight {
    /// Creates a backtracking Dijkstra algorithm for finding all shortest paths.
    ///
    /// This algorithm finds all paths between two vertices that share the optimal (minimum) cost.
    /// It first runs Dijkstra to find the optimal cost, then tracks all predecessors that maintain
    /// that optimal cost, and finally backtracks to enumerate all such paths.
    ///
    /// - Parameter weight: The cost definition for edge weights
    /// - Returns: A backtracking Dijkstra algorithm instance
    @inlinable
    public static func backtrackingDijkstra<Graph: IncidenceGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where 
        Self == BacktrackingDijkstraAllShortestPathsAlgorithm<Graph, Weight>,
        Graph.VertexDescriptor: Hashable
    {
        .init(weight: weight)
    }
}

/// An all shortest paths algorithm based on backtracking Dijkstra.
public struct BacktrackingDijkstraAllShortestPathsAlgorithm<
    Graph: IncidenceGraph,
    Weight: Numeric & Comparable
>: AllShortestPathsUntilAlgorithm, AllShortestPathsAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    public typealias Visitor = BacktrackingDijkstra<Graph, Weight>.Visitor
    
    public let weight: CostDefinition<Graph, Weight>
    
    /// Creates a backtracking Dijkstra all shortest paths algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights
    @inlinable
    public init(weight: CostDefinition<Graph, Weight>) {
        self.weight = weight
    }
    
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
    
    @inlinable
    public func allShortestPaths(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>] {
        let algorithm = BacktrackingDijkstra(on: graph, edgeWeight: weight)
        let result = algorithm.findAllShortestPaths(from: source, to: destination, visitor: visitor)
        return result.paths
    }
}

extension BacktrackingDijkstraAllShortestPathsAlgorithm: VisitorSupporting {}

