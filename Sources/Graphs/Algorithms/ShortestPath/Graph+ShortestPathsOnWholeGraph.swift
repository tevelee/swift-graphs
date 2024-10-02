extension Graph {
    /// Finds the shortest paths from the source node to all other nodes using the specified algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - algorithm: The algorithm to use for finding the shortest paths.
    /// - Returns: A dictionary where the keys are the nodes and the values are the paths from the source node to the respective nodes.
    @inlinable public func shortestPaths<Algorithm: ShortestPathsOnWholeGraphAlgorithm<Node, Edge>>(
        from source: Node,
        using algorithm: Algorithm
    ) -> [Node: Path<Node, Edge>] {
        algorithm.shortestPaths(from: source, in: self)
    }
}

/// A protocol that defines the requirements for a shortest paths algorithm.
public protocol ShortestPathsOnWholeGraphAlgorithm<Node, Edge> {
    /// The type of nodes in the graph.
    associatedtype Node: Hashable
    /// The type of edges in the graph.
    associatedtype Edge

    /// Finds the shortest paths in the graph from the start node to all other nodes.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - graph: The graph in which to find the shortest paths.
    /// - Returns: A dictionary where the keys are the nodes and the values are the paths from the source node to the respective nodes.
    @inlinable func shortestPaths(
        from source: Node,
        in graph: some Graph<Node, Edge>
    ) -> [Node: Path<Node, Edge>]
}
