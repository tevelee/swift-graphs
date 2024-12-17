extension ShortestPathUntilAlgorithm {
    /// Creates a Dijkstra algorithm instance.
    /// - Returns: An instance of `DijkstraAlgorithm`.
    @inlinable public static func dijkstra<Node, Edge>() -> Self where Self == DijkstraAlgorithm<Node, Edge> {
        .init()
    }
}

extension DijkstraAlgorithm: ShortestPathUntilAlgorithm {
    /// Finds the shortest path in the graph from the start node to the goal node using the Dijkstra algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - condition: The completion criteria.
    ///   - graph: The graph in which to find the shortest path.
    /// - Returns: A `Path` instance representing the shortest path, or `nil` if no path is found.
    @inlinable public func shortestPath(
        from source: Node,
        until condition: (Node) -> Bool,
        in graph: some GraphComponent<Node, Edge>
    ) -> Path<Node, Edge>? {
        let result = computeShortestPaths(from: source, condition: condition, in: graph)
        if let destination = result.destination {
            return Path(connectingEdges: result.connectingEdges, source: source, destination: destination)
        } else {
            return nil
        }
    }
}
