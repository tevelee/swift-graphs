extension ShortestPathsOnWholeGraphAlgorithm {
    /// Creates a Bellman-Ford algorithm instance.
    /// - Returns: An instance of `BellmanFordAlgorithm`.
    @inlinable public static func bellmanFord<Node, Edge>(max: Edge.Weight) -> Self where Self == BellmanFordAlgorithm<Node, Edge> {
        .init(max: max)
    }

    /// Creates a Bellman-Ford algorithm instance.
    /// - Returns: An instance of `BellmanFordAlgorithm`.
    @inlinable public static func bellmanFord<Node, Edge>() -> Self where Self == BellmanFordAlgorithm<Node, Edge>, Edge.Weight: FixedWidthInteger {
        .init(max: .max)
    }
}

extension WholeGraphProtocol where Node: Hashable, Edge: Weighted, Edge.Weight: FixedWidthInteger {
    /// Finds the shortest paths from the source node to all other nodes using the Bellman-Ford algorithm.
    /// - Parameter source: The starting node.
    /// - Returns: A dictionary where the keys are the nodes and the values are the paths from the source node to the respective nodes.
    @inlinable public func shortestPaths(
        from source: Node
    ) -> [Node: Path<Node, Edge>] {
        shortestPaths(from: source, using: .bellmanFord())
    }
}

extension BellmanFordAlgorithm: ShortestPathsOnWholeGraphAlgorithm {
    /// Finds the shortest paths in the graph from the start node to all other nodes using the Bellman-Ford algorithm.
    /// - Parameters:
    ///   - graph: The graph in which to find the shortest paths.
    ///   - source: The starting node.
    /// - Returns: A dictionary where the keys are the nodes and the values are the paths from the source node to the respective nodes.
    @inlinable public func shortestPaths(
        from source: Node,
        in graph: some WholeGraphProtocol<Node, Edge>
    ) -> [Node: Path<Node, Edge>] {
        let result = computeShortestPaths(from: source, in: graph)
        var paths: [Node: Path<Node, Edge>] = [:]
        for node in graph.allNodes {
            if node == source {
                paths[node] = Path(source: source, destination: source, edges: [])
            } else if let _ = result.predecessors[node] {
                if let path = Path(connectingEdges: result.predecessors, source: source, destination: node) {
                    paths[node] = path
                }
            }
        }
        return paths
    }
}
