extension ShortestPathsAlgorithm {
    /// Creates a Dijkstra algorithm instance.
    /// - Returns: An instance of `DijkstraAlgorithm`.
    @inlinable public static func dijkstra<Node, Edge>() -> Self where Self == DijkstraAlgorithm<Node, Edge> {
        .init()
    }
}

extension GraphComponent where Node: Hashable, Edge: Weighted, Edge.Weight: Numeric, Edge.Weight.Magnitude == Edge.Weight {
    /// Finds the shortest paths from the source node to all other nodes using the Dijkstra algorithm.
    /// - Parameter source: The starting node.
    /// - Returns: A dictionary where the keys are the nodes and the values are the paths from the source node to the respective nodes.
    @inlinable public func shortestPaths(
        from source: Node
    ) -> [Node: Path<Node, Edge>] {
        shortestPaths(from: source, using: .dijkstra())
    }
}

extension DijkstraAlgorithm: ShortestPathsAlgorithm {
    /// Finds the shortest paths in the graph from the start node to all other nodes using the Dijkstra algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - graph: The graph in which to find the shortest paths.
    /// - Returns: A dictionary where the keys are the nodes and the values are the paths from the source node to the respective nodes.
    @inlinable public func shortestPaths(
        from source: Node,
        in graph: some GraphComponent<Node, Edge>
    ) -> [Node: Path<Node, Edge>] {
        let result = computeShortestPaths(from: source, in: graph)

        var paths: [Node: Path<Node, Edge>] = [:]
        for node in result.connectingEdges.keys {
            if let path = Path(connectingEdges: result.connectingEdges, source: source, destination: node) {
                paths[node] = path
            }
        }

        paths[source] = Path(source: source, destination: source, edges: [])

        return paths
    }
}
