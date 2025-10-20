extension SearchAlgorithm {
    /// Creates a breadth-first search algorithm.
    ///
    /// - Returns: A BFS search algorithm instance.
    @inlinable
    public static func bfs<Graph>() -> Self where Self == BFSSearch<Graph> {
        .init()
    }
}

/// A breadth-first search algorithm implementation for the SearchAlgorithm protocol.
///
/// This struct wraps the core BFS algorithm to provide a SearchAlgorithm interface,
/// making it easy to use BFS as a general search algorithm.
///
/// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
public struct BFSSearch<Graph: IncidenceGraph>: SearchAlgorithm where Graph.VertexDescriptor: Hashable {
    /// The visitor type for observing search progress.
    public typealias Visitor = BreadthFirstSearch<Graph>.Visitor
    
    /// Creates a new BFS search algorithm.
    @inlinable
    public init() {}
    
    /// Performs a breadth-first search from the source vertex.
    ///
    /// - Parameters:
    ///   - source: The vertex to start search from.
    ///   - graph: The graph to search in.
    ///   - visitor: An optional visitor to observe the search progress.
    /// - Returns: A BFS algorithm instance.
    @inlinable
    public func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> BreadthFirstSearch<Graph> {
        BreadthFirstSearch(on: graph, from: source)
    }
}

extension BFSSearch: VisitorSupporting {}
