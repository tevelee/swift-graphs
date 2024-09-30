extension Graph where Edge: Weighted, Node: Hashable {
    /// Finds the minimum spanning tree of the graph using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for finding the minimum spanning tree.
    /// - Returns: An array of `GraphEdge` instances representing the edges in the minimum spanning tree.
    @inlinable public func minimumSpanningTree<Algorithm: MinimumSpanningTreeAlgorithm>(
        using algorithm: Algorithm
    ) -> [GraphEdge<Node, Edge>] where Algorithm.Node == Node, Algorithm.Edge == Edge {
        algorithm.minimumSpanningTree(in: self)
    }
}

/// A protocol that defines the requirements for a minimum spanning tree algorithm.
public protocol MinimumSpanningTreeAlgorithm<Node, Edge> {
    /// The type of nodes in the graph.
    associatedtype Node
    /// The type of edges in the graph, which must conform to the `Weighted` protocol.
    associatedtype Edge: Weighted

    /// Finds the minimum spanning tree in the graph.
    /// - Parameter graph: The graph in which to find the minimum spanning tree.
    /// - Returns: An array of `GraphEdge` instances representing the edges in the minimum spanning tree.
    func minimumSpanningTree(in graph: some Graph<Node, Edge>) -> [GraphEdge<Node, Edge>]
}
