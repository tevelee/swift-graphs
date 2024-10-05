extension Graph {
    @inlinable public func kShortestPaths(
        from source: Node,
        to destination: Node,
        k: Int,
        using algorithm: some KShortestPathsAlgorithm<Node, Edge>
    ) -> [Path<Node, Edge>] {
        algorithm.kShortestPaths(from: source, to: destination, k: k, in: self)
    }
}

/// A protocol that defines the requirements for an algorithm that computes the K shortest paths between two nodes in a graph.
public protocol KShortestPathsAlgorithm<Node, Edge> {
    /// The type of nodes in the graph.
    associatedtype Node
    /// The type of edges in the graph.
    associatedtype Edge

    /// Finds the K shortest paths from the source node to the destination node in the graph.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - k: The number of shortest paths to find.
    ///   - graph: The graph in which to find the shortest paths.
    /// - Returns: An array of `Path` instances representing the K shortest paths.
    @inlinable func kShortestPaths(
        from source: Node,
        to destination: Node,
        k: Int,
        in graph: some Graph<Node, Edge>
    ) -> [Path<Node, Edge>]
}
