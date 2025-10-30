extension Graph where Self: IncidenceGraph, VertexDescriptor: Hashable {
    /// Performs a graph traversal using the specified algorithm.
    ///
    /// - Parameters:
    ///   - source: The starting vertex for the traversal
    ///   - algorithm: The traversal algorithm to use
    /// - Returns: A result containing the vertices and edges visited during traversal
    @inlinable
    public func traverse(
        from source: VertexDescriptor,
        using algorithm: some TraversalAlgorithm<Self>
    ) -> TraversalResult<VertexDescriptor, EdgeDescriptor> {
        algorithm.traverse(from: source, in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension Graph where Self: IncidenceGraph, VertexDescriptor: Hashable {
    /// Performs a depth-first traversal starting from the specified vertex.
    ///
    /// - Parameter source: The starting vertex for the traversal
    /// - Returns: A result containing the vertices and edges visited during traversal
    @inlinable
    public func traverse(from source: VertexDescriptor) -> TraversalResult<VertexDescriptor, EdgeDescriptor> {
        traverse(from: source, using: .dfs())
    }
}

/// A protocol for graph traversal algorithms.
///
/// Traversal algorithms visit vertices and edges in a specific order, such as
/// depth-first search (DFS) or breadth-first search (BFS). This protocol provides
/// a unified interface for different traversal strategies.
public protocol TraversalAlgorithm<Graph> {
    /// The type of graph this algorithm operates on.
    associatedtype Graph: IncidenceGraph
    
    /// The type of visitor used for algorithm events.
    associatedtype Visitor

    /// Performs a traversal of the graph starting from the specified vertex.
    ///
    /// - Parameters:
    ///   - source: The starting vertex for the traversal
    ///   - graph: The graph to traverse
    ///   - visitor: Optional visitor for algorithm events
    /// - Returns: A result containing the vertices and edges visited during traversal
    func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor>
}

/// The result of a graph traversal operation.
///
/// Contains the vertices and edges that were visited during the traversal,
/// in the order they were encountered.
public struct TraversalResult<Vertex, Edge> {
    /// The vertices visited during the traversal.
    public let vertices: [Vertex]
    
    /// The edges traversed during the traversal.
    public let edges: [Edge]
    
    /// Creates a new traversal result.
    ///
    /// - Parameters:
    ///   - vertices: The vertices visited during the traversal
    ///   - edges: The edges traversed during the traversal
    @inlinable
    public init(vertices: [Vertex], edges: [Edge]) {
        self.vertices = vertices
        self.edges = edges
    }
}

extension TraversalResult: Sendable where Vertex: Sendable, Edge: Sendable {}

extension VisitorWrapper: TraversalAlgorithm where Base: TraversalAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    
    @inlinable
    public func traverse(
        from source: Base.Graph.VertexDescriptor,
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> TraversalResult<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor> {
        base.traverse(from: source, in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
