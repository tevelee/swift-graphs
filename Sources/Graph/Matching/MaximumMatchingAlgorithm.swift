extension BipartiteGraphProtocol where Node: Hashable {
    /// Finds the maximum matching in the graph using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for finding the maximum matching.
    /// - Returns: A dictionary where the keys are the nodes in the first partition and the values are the nodes in the second partition.
    @inlinable public func maximumMatching<Algorithm: MaximumMatchingAlgorithm>(
        using algorithm: Algorithm
    ) -> [Node: Node] where Algorithm.Node == Node, Algorithm.Edge == Edge {
        algorithm.maximumMatching(in: self)
    }
}

/// A protocol that defines the requirements for a maximum matching algorithm.
public protocol MaximumMatchingAlgorithm {
    /// The type of nodes in the graph.
    associatedtype Node: Hashable
    /// The type of edges in the graph.
    associatedtype Edge

    /// Finds the maximum matching in the graph.
    /// - Parameter graph: The graph in which to find the maximum matching.
    /// - Returns: A dictionary where the keys are the nodes in the first partition and the values are the nodes in the second partition.
    @inlinable func maximumMatching(
        in graph: some BipartiteGraphProtocol<Node, Edge>
    ) -> [Node: Node]
}
