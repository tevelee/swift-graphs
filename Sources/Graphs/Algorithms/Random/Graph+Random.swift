/// An algorithm for generating random graphs.
public protocol RandomGraphGeneration<Node, Edge> {
    /// The type of the nodes in the graph.
    associatedtype Node
    /// The type of the edges in the graph.
    associatedtype Edge

    /// Generates a random graph.
    @inlinable func generateRandomGraph() -> (nodes: [Node], edges: [GraphEdge<Node, Edge>])
}

/// An algorithm for generating random binary graphs.
public protocol RandomBinaryGraphGeneration<Node, Edge> {
    /// The type of the nodes in the graph.
    associatedtype Node: Hashable
    /// The type of the edges in the graph.
    associatedtype Edge

    /// Generates a random binary graph.
    /// - Returns: A tuple containing the nodes and edges of the graph.
    @inlinable func generateRandomBinaryGraph() -> (nodes: [Node], edges: [BinaryGraphEdges<Node, Edge>])
}
