extension Graph where Node: Hashable {
    /// Colors the nodes of the graph using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for coloring the nodes.
    /// - Returns: A dictionary where the keys are the nodes and the values are the colors assigned to the nodes.
    @inlinable public func colorNodes(
        using algorithm: some GraphColoringAlgorithm<Node, Edge>
    ) -> [Node: Int] {
        algorithm.coloring(of: self)
    }
}

/// A protocol that defines the requirements for a graph coloring algorithm.
public protocol GraphColoringAlgorithm<Node, Edge> {
    /// The type of nodes in the graph.
    associatedtype Node: Hashable
    /// The type of edges in the graph.
    associatedtype Edge

    /// Colors the nodes of the graph.
    /// - Parameter graph: The graph in which to color the nodes.
    /// - Returns: A dictionary where the keys are the nodes and the values are the colors assigned to the nodes.
    @inlinable func coloring(
        of graph: some Graph<Node, Edge>
    ) -> [Node: Int]
}
