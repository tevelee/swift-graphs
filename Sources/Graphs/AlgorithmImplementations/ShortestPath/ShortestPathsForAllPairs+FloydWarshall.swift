import Foundation

extension ShortestPathsForAllPairsAlgorithm where Weight: AdditiveArithmetic {
    /// Creates a Floyd-Warshall algorithm for computing all-pairs shortest paths.
    ///
    /// - Parameter weight: The cost definition for edge weights.
    /// - Returns: A Floyd-Warshall algorithm instance.
    @inlinable
    public static func floydWarshall<Graph: IncidenceGraph & VertexListGraph & EdgePropertyGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == FloydWarshallAllPairs<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

/// A Floyd-Warshall algorithm implementation for all-pairs shortest paths.
public struct FloydWarshallAllPairs<
    Graph: IncidenceGraph & VertexListGraph & EdgePropertyGraph,
    Weight: AdditiveArithmetic & Comparable
>: ShortestPathsForAllPairsAlgorithm where
    Graph.VertexDescriptor: Hashable
{
    /// The visitor type for this algorithm.
    public typealias Visitor = FloydWarshall<Graph, Weight>.Visitor
    
    /// The cost definition for edge weights.
    public let weight: CostDefinition<Graph, Weight>
    
    /// Creates a new Floyd-Warshall all-pairs algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights.
    @inlinable
    public init(weight: CostDefinition<Graph, Weight>) {
        self.weight = weight
    }
    
    /// Computes shortest paths between all pairs of vertices.
    ///
    /// - Parameters:
    ///   - graph: The graph to compute shortest paths for.
    ///   - visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: The shortest paths between all pairs of vertices.
    @inlinable
    public func shortestPathsForAllPairs(in graph: Graph, visitor: Visitor?) -> AllPairsShortestPaths<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
        let floydWarshall = FloydWarshall(on: graph, edgeWeight: weight)
        return floydWarshall.shortestPathsForAllPairs(visitor: visitor)
    }
}

extension FloydWarshallAllPairs: VisitorSupporting {}
