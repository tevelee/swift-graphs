extension DisjointGraph {
    /// Generates a random graph using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for generating the random graph.
    /// - Returns: A random graph.
    @inlinable public static func random<Algorithm: RandomGraphGeneration<Node, Edge>>(
        using algorithm: Algorithm
    ) -> DisjointGraph<Node, Edge> where Node: Equatable {
        let (nodes, edges) = algorithm.generateRandomGraph()
        return .init(nodes: nodes, edges: edges)
    }
}

extension DisjointHashGraph {
    /// Generates a random graph using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for generating the random graph.
    /// - Returns: A random graph.
    @inlinable public static func random<Algorithm: RandomGraphGeneration<Node, Edge>>(
        using algorithm: Algorithm
    ) -> DisjointHashGraph<Node, Edge, Node> {
        let (nodes, edges) = algorithm.generateRandomGraph()
        return .init(nodes: nodes, edges: edges)
    }
}

extension DisjointBinaryGraph where Node: Hashable {
    /// Generates a random graph using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for generating the random graph.
    /// - Returns: A random graph.
    @inlinable public static func random<Algorithm: RandomBinaryGraphGeneration<Node, Edge>>(
        using algorithm: Algorithm
    ) -> DisjointBinaryGraph<Node, Edge> {
        let (nodes, edges) = algorithm.generateRandomBinaryGraph()
        return .init(nodes: nodes, edges: edges)
    }
}

extension DisjointBinaryHashGraph {
    /// Generates a random graph using the specified algorithm.
    /// - Parameter algorithm: The algorithm to use for generating the random graph.
    /// - Returns: A random graph.
    @inlinable public static func random<Algorithm: RandomBinaryGraphGeneration<Node, Edge>>(
        using algorithm: Algorithm
    ) -> DisjointBinaryHashGraph<Node, Edge, Node> where Node: Hashable {
        let (nodes, edges) = algorithm.generateRandomBinaryGraph()
        return .init(nodes: nodes, edges: edges)
    }
}
