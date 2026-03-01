extension ShortestPathAlgorithm {
    /// Creates a bidirectional Dijkstra shortest path algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights.
    /// - Returns: A bidirectional Dijkstra shortest path algorithm instance.
    @inlinable
    public static func bidirectionalDijkstra<Graph: IncidenceGraph & BidirectionalGraph, Weight: Numeric>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == BidirectionalDijkstraShortestPath<Graph, Weight>, Weight.Magnitude == Weight, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

/// A bidirectional Dijkstra shortest path algorithm implementation for the ShortestPathAlgorithm protocol.
///
/// This struct wraps the core bidirectional Dijkstra algorithm to provide a ShortestPathAlgorithm interface,
/// making it easy to use bidirectional Dijkstra for finding shortest paths efficiently.
///
/// - Complexity: O((V + E) log V) where V is the number of vertices and E is the number of edges
public struct BidirectionalDijkstraShortestPath<
    Graph: IncidenceGraph & BidirectionalGraph,
    Weight: Numeric & Comparable
>: ShortestPathAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    /// The cost definition for edge weights.
    public let weight: CostDefinition<Graph, Weight>
    
    /// Creates a new bidirectional Dijkstra shortest path algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights.
    @inlinable
    public init(weight: CostDefinition<Graph, Weight>) {
        self.weight = weight
    }
    
    /// Finds the shortest path from source to destination using bidirectional Dijkstra.
    ///
    /// - Parameters:
    ///   - source: The source vertex
    ///   - destination: The destination vertex
    ///   - graph: The graph to search in
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: The shortest path, if one exists
    @inlinable
    public func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: BidirectionalDijkstra<Graph, Weight>.Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let bidirectionalDijkstra = BidirectionalDijkstra(on: graph, edgeWeight: weight)
        let result = bidirectionalDijkstra.shortestPath(from: source, to: destination)
        return result.path
    }
}

extension BidirectionalDijkstraShortestPath: VisitorSupporting {}
