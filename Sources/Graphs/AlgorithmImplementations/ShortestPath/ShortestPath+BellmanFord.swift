import Foundation

extension ShortestPathAlgorithm where Weight: AdditiveArithmetic {
    /// Creates a Bellman-Ford shortest path algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights.
    /// - Returns: A Bellman-Ford shortest path algorithm instance.
    @inlinable
    public static func bellmanFord<Graph: IncidenceGraph & EdgeListGraph & EdgePropertyGraph & VertexListGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == BellmanFordShortestPath<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

/// A Bellman-Ford shortest path algorithm implementation for the ShortestPathAlgorithm protocol.
///
/// This struct wraps the core Bellman-Ford algorithm to provide a ShortestPathAlgorithm interface,
/// making it easy to use Bellman-Ford for finding shortest paths in graphs with negative weights.
///
/// - Complexity: O(VE) where V is the number of vertices and E is the number of edges
public struct BellmanFordShortestPath<
    Graph: IncidenceGraph & EdgeListGraph & EdgePropertyGraph & VertexListGraph,
    Weight: AdditiveArithmetic & Comparable
>: ShortestPathAlgorithm where
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
        let bellmanFord = BellmanFord(on: graph, edgeWeight: weight)
        let result = bellmanFord.shortestPathsFromSource(source, visitor: visitor)
        
        // Check if there's a negative cycle
        guard !result.hasNegativeCycle else { return nil }
        
        // Check if destination is reachable
        guard let distance = result.distances[destination], 
              case .finite = distance else { return nil }
        
        // Reconstruct path
        return reconstructPath(from: source, to: destination, predecessors: result.predecessors, in: graph)
    }
    
    /// Reconstructs the shortest path from predecessors.
    ///
    /// - Parameters:
    ///   - source: The source vertex
    ///   - destination: The destination vertex
    ///   - predecessors: The predecessor map from Bellman-Ford
    ///   - graph: The graph to reconstruct the path in
    /// - Returns: The reconstructed path, if one exists
    @usableFromInline
    func reconstructPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        predecessors: [Graph.VertexDescriptor: Graph.EdgeDescriptor?],
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        var path: [Graph.VertexDescriptor] = [destination]
        var edges: [Graph.EdgeDescriptor] = []
        var current = destination
        
        while current != source {
            guard let edge = predecessors[current] else { return nil }
            guard let unwrappedEdge = edge else { return nil }
            edges.append(unwrappedEdge)
            
            // Find the source vertex of this edge
            guard let sourceVertex = graph.source(of: unwrappedEdge) else { return nil }
            path.append(sourceVertex)
            current = sourceVertex
        }
        
        path.reverse()
        edges.reverse()
        
        return Path(
            source: source,
            destination: destination,
            vertices: path,
            edges: edges
        )
    }
}

extension BellmanFordShortestPath: VisitorSupporting {}
