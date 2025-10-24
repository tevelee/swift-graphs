/// A protocol for algorithms that compute shortest paths between all pairs of vertices.
public protocol ShortestPathsForAllPairsAlgorithm<Graph, Weight> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    /// The weight type used for edge weights.
    associatedtype Weight: AdditiveArithmetic & Comparable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Computes shortest paths between all pairs of vertices.
    ///
    /// - Parameters:
    ///   - graph: The graph to compute shortest paths for.
    ///   - visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: The shortest paths between all pairs of vertices.
    func shortestPathsForAllPairs(in graph: Graph, visitor: Visitor?) -> AllPairsShortestPaths<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight>
}

/// A result containing shortest paths between all pairs of vertices.
public struct AllPairsShortestPaths<Vertex: Hashable, Edge, Weight: AdditiveArithmetic & Comparable> {
    /// The distances between all pairs of vertices.
    public let distances: [Vertex: [Vertex: Cost<Weight>]]
    /// The predecessors for reconstructing paths.
    public let predecessors: [Vertex: [Vertex: Edge?]]
    
    /// Creates a new all-pairs shortest paths result.
    ///
    /// - Parameters:
    ///   - distances: The distances between all pairs of vertices.
    ///   - predecessors: The predecessors for reconstructing paths.
    @inlinable
    public init(distances: [Vertex: [Vertex: Cost<Weight>]], predecessors: [Vertex: [Vertex: Edge?]]) {
        self.distances = distances
        self.predecessors = predecessors
    }
    
    /// Gets the distance between two vertices.
    ///
    /// - Parameters:
    ///   - source: The source vertex.
    ///   - destination: The destination vertex.
    /// - Returns: The distance between the vertices, or `nil` if no path exists.
    @inlinable
    public func distance(from source: Vertex, to destination: Vertex) -> Cost<Weight>? {
        distances[source]?[destination]
    }
    
    /// Checks if there is a path between two vertices.
    ///
    /// - Parameters:
    ///   - source: The source vertex.
    ///   - destination: The destination vertex.
    /// - Returns: `true` if a path exists, `false` otherwise.
    @inlinable
    public func hasPath(from source: Vertex, to destination: Vertex) -> Bool {
        guard let cost = distances[source]?[destination] else { return false }
        switch cost {
            case .infinite: return false
            case .finite: return true
        }
    }
    
    /// Gets the shortest path between two vertices.
    ///
    /// - Parameters:
    ///   - source: The source vertex.
    ///   - destination: The destination vertex.
    ///   - graph: The graph to reconstruct the path in.
    /// - Returns: The shortest path, or `nil` if no path exists.
    @inlinable
    public func path(from source: Vertex, to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> Path<Vertex, Edge>? {
        guard predecessors[source]?[destination] != nil else {
            return nil
        }
        
        // Reconstruct path by following predecessors
        var current = destination
        var vertices: [Vertex] = [destination]
        var edges: [Edge] = []
        
        while let edge = predecessors[source]?[current] {
            guard let edge = edge else { break }
            edges.insert(edge, at: 0)
            guard let predecessor = graph.source(of: edge) else { break }
            if predecessor == source { break }
            vertices.insert(predecessor, at: 0)
            current = predecessor
        }
        
        vertices.insert(source, at: 0)
        
        return Path(
            source: source,
            destination: destination,
            vertices: vertices,
            edges: edges
        )
    }
    
}

extension IncidenceGraph where Self: VertexListGraph {
    /// Computes shortest paths between all pairs of vertices using the specified algorithm.
    ///
    /// - Parameter algorithm: The algorithm to use for computing shortest paths.
    /// - Returns: The shortest paths between all pairs of vertices.
    @inlinable
    public func shortestPathsForAllPairs<Weight: AdditiveArithmetic & Comparable>(
        using algorithm: some ShortestPathsForAllPairsAlgorithm<Self, Weight>
    ) -> AllPairsShortestPaths<VertexDescriptor, EdgeDescriptor, Weight> {
        algorithm.shortestPathsForAllPairs(in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Finds shortest paths between all pairs of vertices using Floyd-Warshall algorithm as the default.
    /// This is efficient for dense graphs and when you need all-pairs shortest paths.
    ///
    /// - Parameter weight: The cost definition for edge weights.
    /// - Returns: The shortest paths between all pairs of vertices.
    @inlinable
    public func shortestPathsForAllPairs<Weight: AdditiveArithmetic & Comparable>(
        weight: CostDefinition<Self, Weight>
    ) -> AllPairsShortestPaths<VertexDescriptor, EdgeDescriptor, Weight> {
        shortestPathsForAllPairs(using: .floydWarshall(weight: weight))
    }
}

extension VisitorWrapper: ShortestPathsForAllPairsAlgorithm where Base: ShortestPathsForAllPairsAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    public typealias Weight = Base.Weight
    
    @inlinable
    public func shortestPathsForAllPairs(in graph: Base.Graph, visitor: Base.Visitor?) -> AllPairsShortestPaths<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor, Base.Weight> {
        base.shortestPathsForAllPairs(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
