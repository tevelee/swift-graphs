extension WholeGraphProtocol {
    /// Computes the shortest paths from all nodes to all other nodes in the graph using the specified algorithm.
    @inlinable public func shortestPathsForAllPairs<Algorithm: ShortestPathsForAllPairsAlgorithm<Node, Edge>>(
        using algorithm: Algorithm
    ) -> [Node: [Node: Edge.Weight]] {
        algorithm.shortestPathsForAllPairs(in: self)
    }
}

/// A protocol that defines the requirements for an algorithm that computes the shortest paths for all pairs of nodes in a graph.
public protocol ShortestPathsForAllPairsAlgorithm<Node, Edge> {
    associatedtype Node: Hashable
    associatedtype Edge: Weighted where Edge.Weight: Numeric

    @inlinable func shortestPathsForAllPairs(
        in graph: some WholeGraphProtocol<Node, Edge>
    ) -> [Node: [Node: Edge.Weight]]
}
