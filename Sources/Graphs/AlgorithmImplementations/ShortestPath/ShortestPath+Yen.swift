extension ShortestPathAlgorithm where Weight: AdditiveArithmetic {
    /// Creates a Yen shortest path algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights.
    /// - Returns: A Yen shortest path algorithm instance.
    @inlinable
    public static func yen<Graph: IncidenceGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == YenShortestPath<Graph, Weight>, Graph.VertexDescriptor: Hashable, Graph.EdgeDescriptor: Hashable {
        .init(weight: weight)
    }
}

/// A Yen shortest path algorithm implementation for the ShortestPathAlgorithm protocol.
///
/// This struct wraps the core Yen algorithm to provide a ShortestPathAlgorithm interface,
/// making it easy to use Yen for finding the shortest path (first of k shortest paths).
///
/// - Complexity: O(k * V * (E + V log V)) where k is the number of paths, V is vertices, E is edges
public struct YenShortestPath<
    Graph: IncidenceGraph,
    Weight: Numeric & Comparable
>: ShortestPathAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Graph.EdgeDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    /// The visitor type for observing algorithm progress.
    public typealias Visitor = Yen<Graph, Weight>.Visitor
    
    /// The cost definition for edge weights.
    public let weight: CostDefinition<Graph, Weight>
    
    /// Creates a new Yen shortest path algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights.
    @inlinable
    public init(weight: CostDefinition<Graph, Weight>) {
        self.weight = weight
    }
    
    /// Finds the shortest path from source to destination using Yen's algorithm.
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
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let yen = Yen(edgeWeight: weight)
        let paths = yen.kShortestPaths(from: source, to: destination, k: 1, in: graph, visitor: visitor)
        return paths.first
    }
}

extension YenShortestPath: VisitorSupporting {}
