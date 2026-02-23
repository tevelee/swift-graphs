extension ShortestPathAlgorithm {
    /// Creates a Johnson shortest path algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights.
    /// - Returns: A Johnson shortest path algorithm instance.
    @inlinable
    public static func johnson<Graph: IncidenceGraph & VertexListGraph, Weight: Numeric>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == JohnsonShortestPath<Graph, Weight>, Graph.VertexDescriptor: Hashable, Weight.Magnitude == Weight {
        .init(weight: weight)
    }
}

/// A Johnson shortest path algorithm implementation for the ShortestPathAlgorithm protocol.
///
/// This struct wraps the core Johnson algorithm to provide a ShortestPathAlgorithm interface,
/// making it easy to use Johnson for finding shortest paths in graphs with negative weights.
///
/// - Complexity: O(V^2 log V + VE) where V is the number of vertices and E is the number of edges
public struct JohnsonShortestPath<
    Graph: IncidenceGraph & VertexListGraph,
    Weight: AdditiveArithmetic & Comparable
>: ShortestPathAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Weight: Numeric,
    Weight.Magnitude == Weight
{
    /// The visitor type for observing algorithm progress.
    public typealias Visitor = Johnson<Graph, Weight>.Visitor
    
    /// The cost definition for edge weights.
    public let weight: CostDefinition<Graph, Weight>
    
    /// Creates a new Johnson shortest path algorithm.
    ///
    /// - Parameter weight: The cost definition for edge weights.
    @inlinable
    public init(weight: CostDefinition<Graph, Weight>) {
        self.weight = weight
    }
    
    /// Finds the shortest path from source to destination using Johnson's algorithm.
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
        let johnson = Johnson(edgeWeight: weight)
        let allPairs = johnson.shortestPathsForAllPairs(in: graph, visitor: visitor)
        
        // Check if destination is reachable
        guard case .finite = allPairs.distance(from: source, to: destination) else { return nil }
        
        // Reconstruct path
        return reconstructPath(from: source, to: destination, predecessors: allPairs.predecessors, in: graph)
    }
    
    /// Reconstructs the shortest path from predecessors.
    ///
    /// - Parameters:
    ///   - source: The source vertex
    ///   - destination: The destination vertex
    ///   - predecessors: The predecessor map from Johnson
    ///   - graph: The graph to reconstruct the path in
    /// - Returns: The reconstructed path, if one exists
    @usableFromInline
    func reconstructPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        predecessors: [Graph.VertexDescriptor: [Graph.VertexDescriptor: Graph.EdgeDescriptor?]],
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        var path: [Graph.VertexDescriptor] = [destination]
        var edges: [Graph.EdgeDescriptor] = []
        var current = destination
        
        while current != source {
            guard let edge = predecessors[source]?[current] else { return nil }
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

extension JohnsonShortestPath: VisitorSupporting {}
