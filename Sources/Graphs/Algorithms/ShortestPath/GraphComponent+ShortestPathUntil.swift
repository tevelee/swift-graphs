extension GraphComponent where Edge: Weighted {
    /// Finds the shortest path from the source node to the destination node using the specified algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - condition: The completion criteria.
    ///   - algorithm: The algorithm to use for finding the shortest path.
    /// - Returns: A `Path` instance representing the shortest path, or `nil` if no path is found.
    @inlinable public func shortestPath(
        from source: Node,
        until condition: (Node) -> Bool,
        using algorithm: some ShortestPathUntilAlgorithm<Node, Edge>
    ) -> Path<Node, Edge>? {
        algorithm.shortestPath(from: source, until: condition, in: self)
    }
}

extension ShortestPathUntilAlgorithm {
    /// Creates a Dijkstra algorithm instance.
    /// - Returns: An instance of `DijkstraAlgorithm`.
    @inlinable public static func dijkstra<Node, Edge>() -> Self where Self == DijkstraAlgorithm<Node, Edge> {
        .init()
    }
}

/// A protocol that defines the requirements for a shortest path algorithm.
public protocol ShortestPathUntilAlgorithm<Node, Edge> {
    /// The type of nodes in the graph.
    associatedtype Node
    /// The type of edges in the graph.
    associatedtype Edge

    /// Finds the shortest path in the graph from the start node to the goal node.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - condition: The completion criteria.
    ///   - graph: The graph in which to find the shortest path.
    /// - Returns: A `Path` instance representing the shortest path, or `nil` if no path is found.
    @inlinable func shortestPath(
        from source: Node,
        until condition: (Node) -> Bool,
        in graph: some GraphComponent<Node, Edge>
    ) -> Path<Node, Edge>?
}

extension ShortestPathAlgorithm where Self: ShortestPathUntilAlgorithm {
    /// Finds the shortest path from the source node to the destination node in the graph.
    /// - Parameter source: The starting node.
    /// - Parameter destination: The target node.
    /// - Parameter condition: A closure that determines when to stop the search.
    /// - Parameter graph: The graph in which to compute the shortest path.
    /// - Returns: The shortest path from the source node to the destination node.
    @inlinable public func shortestPath(
        from source: Node,
        to destination: Node,
        satisfying condition: (Node) -> Bool,
        in graph: some GraphComponent<Node, Edge>
    ) -> Path<Node, Edge>? {
        shortestPath(from: source, until: condition, in: graph)
    }
}

