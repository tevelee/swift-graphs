extension Graph where Node: Hashable, Edge: Weighted {
    /// Finds the shortest path from the source node to the destination node using the specified algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - algorithm: The algorithm to use for finding the shortest path.
    /// - Returns: A `Path` instance representing the shortest path, or `nil` if no path is found.
    @inlinable public func shortestPath(
        from source: Node,
        to destination: Node,
        using algorithm: some ShortestPathOnWholeGraphAlgorithm<Node, Edge>
    ) -> Path<Node, Edge>? {
        algorithm.shortestPath(from: source, to: destination, in: self)
    }
}

/// A protocol that defines the requirements for a shortest path algorithm on a whole graph.
public protocol ShortestPathOnWholeGraphAlgorithm<Node, Edge> {
    /// The type of nodes in the graph.
    associatedtype Node
    /// The type of edges in the graph.
    associatedtype Edge

    /// Finds the shortest path in the graph from the start node to the goal node.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - graph: The graph in which to find the shortest path.
    /// - Returns: A `Path` instance representing the shortest path, or `nil` if no path is found.
    @inlinable func shortestPath(
        from source: Node,
        to destination: Node,
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>?
}
