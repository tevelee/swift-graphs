import Foundation

extension KShortestPathsAlgorithm where Weight: AdditiveArithmetic {
    /// Creates a Yen k-shortest paths algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights.
    /// - Returns: A Yen k-shortest paths algorithm instance.
    @inlinable
    public static func yen<Graph: IncidenceGraph & EdgePropertyGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == YenKShortestPath<Graph, Weight>, Graph.VertexDescriptor: Hashable, Graph.EdgeDescriptor: Hashable {
        .init(weight: weight)
    }
}

/// A Yen k-shortest paths algorithm implementation for the KShortestPathsAlgorithm protocol.
///
/// This struct wraps the core Yen algorithm to provide a KShortestPathsAlgorithm interface,
/// making it easy to use Yen for finding k shortest paths between two vertices.
///
/// - Complexity: O(k * V * (E + V log V)) where k is the number of paths, V is vertices, E is edges
public struct YenKShortestPath<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
>: KShortestPathsAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Graph.EdgeDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    /// The visitor type for observing algorithm progress.
    public typealias Visitor = Yen<Graph, Weight>.Visitor
    
    /// The cost definition for edge weights.
    public let weight: CostDefinition<Graph, Weight>
    
    /// Creates a new Yen k-shortest paths algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights.
    @inlinable
    public init(weight: CostDefinition<Graph, Weight>) {
        self.weight = weight
    }
    
    /// Finds the k shortest paths from source to destination using Yen's algorithm.
    ///
    /// - Parameters:
    ///   - source: The source vertex
    ///   - destination: The destination vertex
    ///   - k: The number of shortest paths to find
    ///   - graph: The graph to search in
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: An array of the k shortest paths, ordered by cost
    @inlinable
    public func kShortestPaths(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        k: Int,
        in graph: Graph,
        visitor: Visitor?
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>] {
        let yen = Yen(edgeWeight: weight)
        return yen.kShortestPaths(from: source, to: destination, k: k, in: graph, visitor: visitor)
    }
}

extension YenKShortestPath: VisitorSupporting {}
