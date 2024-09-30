extension AdjacencyListGraph {
    /// Generates a random graph using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for generating the random graph.
    /// - Returns: A random graph.
    @inlinable public static func random<Algorithm: RandomGraphGeneration<Node, Edge>>(using algorithm: Algorithm) -> AdjacencyListGraph<Node, Edge> {
        algorithm.generateRandomGraph()
    }
}

/// An algorithm for generating random graphs.
public protocol RandomGraphGeneration<Node, Edge> {
    /// The type of the nodes in the graph.
    associatedtype Node
    /// The type of the edges in the graph.
    associatedtype Edge

    /// Generates a random graph.
    @inlinable func generateRandomGraph() -> AdjacencyListGraph<Node, Edge>
}
