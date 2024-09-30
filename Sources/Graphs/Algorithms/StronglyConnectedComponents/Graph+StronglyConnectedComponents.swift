extension Graph {
    /// Finds the strongly connected components in the graph using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for finding the strongly connected components.
    /// - Returns: An array of arrays, where each inner array contains the nodes of a strongly connected component.
    @inlinable public func findStronglyConnectedComponents<Algorithm: StronglyConnectedComponentsAlgorithm<Node, Edge>>(
        using algorithm: Algorithm
    ) -> [[Node]] {
        algorithm.findStronglyConnectedComponents(in: self)
    }
}

/// A protocol that defines the requirements for a strongly connected components algorithm.
public protocol StronglyConnectedComponentsAlgorithm<Node, Edge> {
    /// The type of nodes in the graph.
    associatedtype Node: Hashable
    /// The type of edges in the graph.
    associatedtype Edge

    /// Finds the strongly connected components in the graph.
    /// - Parameter graph: The graph in which to find the strongly connected components.
    /// - Returns: An array of arrays, where each inner array contains the nodes of a strongly connected component.
    func findStronglyConnectedComponents(in graph: some Graph<Node, Edge>) -> [[Node]]
}
