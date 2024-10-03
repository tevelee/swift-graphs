extension ConnectedGraph {
    /// Generates a random graph using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for generating the random graph.
    /// - Returns: A random graph.
    @inlinable public static func random<Algorithm: RandomGraphGeneration<Node, Edge>>(
        using algorithm: Algorithm
    ) -> ConnectedGraph<Node, Edge> where Node: Equatable {
        .init(edges: algorithm.generateRandomGraph().edges)
    }
}

extension ConnectedHashGraph {
    /// Generates a random graph using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for generating the random graph.
    /// - Returns: A random graph.
    @inlinable public static func random<Algorithm: RandomGraphGeneration<Node, Edge>>(
        using algorithm: Algorithm
    ) -> ConnectedHashGraph<Node, Edge, Node> {
        .init(edges: algorithm.generateRandomGraph().edges)
    }
}

extension ConnectedBinaryGraph {
    /// Generates a random graph using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for generating the random graph.
    /// - Returns: A random graph.
    @inlinable public static func random<Algorithm: RandomBinaryGraphGeneration<Node, Edge>>(
        using algorithm: Algorithm
    ) -> ConnectedBinaryGraph<Node, Edge> {
        .init(edges: algorithm.generateRandomBinaryGraph().edges)
    }
}

extension ConnectedBinaryHashGraph {
    /// Generates a random graph using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for generating the random graph.
    /// - Returns: A random graph.
    @inlinable public static func random<Algorithm: RandomBinaryGraphGeneration<Node, Edge>>(
        using algorithm: Algorithm
    ) -> ConnectedBinaryHashGraph<Node, Edge, Node> where Node: Hashable {
        .init(edges: algorithm.generateRandomBinaryGraph().edges)
    }
}
