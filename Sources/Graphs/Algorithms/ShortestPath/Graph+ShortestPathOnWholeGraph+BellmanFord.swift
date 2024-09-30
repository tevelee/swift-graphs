extension ShortestPathOnWholeGraphAlgorithm {
    /// Creates a Bellman-Ford algorithm instance.
    /// - Parameter max: The maximum weight of an edge in the graph.
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

/// An implementation of the Bellman-Ford algorithm for finding the shortest path in a graph.
public struct BellmanFordAlgorithm<Node: Hashable, Edge: Weighted>: ShortestPathOnWholeGraphAlgorithm where Edge.Weight: Numeric {
    /// The maximum value possible for weight.
    public let max: Edge.Weight

    /// Initializes a new `BellmanFordAlgorithm` instance.
    /// - Parameter max: The maximum value possible for weight.
    @inlinable public init(max: Edge.Weight) {
        self.max = max
    }

    /// Finds the shortest path in the graph from the start node to the goal node using the Bellman-Ford algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - graph: The graph in which to find the shortest path.
    /// - Returns: A `Path` instance representing the shortest path, or `nil` if no path is found.
    @inlinable public func shortestPath(
        from source: Node,
        to destination: Node,
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>? {
        let result = computeShortestPaths(from: source, in: graph)
        return Path(connectingEdges: result.predecessors, source: source, destination: destination)
    }

    /// Computes the shortest paths from the source node to all other nodes in the graph using the Bellman-Ford algorithm.
    @usableFromInline func computeShortestPaths(
        from source: Node,
        in graph: some Graph<Node, Edge>
    ) -> (distances: [Node: Edge.Weight], predecessors: [Node: GraphEdge<Node, Edge>]) {
        var distances: [Node: Edge.Weight] = [:]
        var predecessors: [Node: GraphEdge<Node, Edge>] = [:]

        for node in graph.allNodes {
            distances[node] = max
        }
        distances[source] = .zero

        for _ in 1..<graph.allNodes.count {
            for edge in graph.allEdges {
                let currentDistance = distances[edge.source] ?? max
                let newDistance = currentDistance + edge.value.weight

                if newDistance < (distances[edge.destination] ?? max) {
                    distances[edge.destination] = newDistance
                    predecessors[edge.destination] = edge
                }
            }
        }

        // Check for negative-weight cycles
        for edge in graph.allEdges {
            let currentDistance = distances[edge.source] ?? max
            let newDistance = currentDistance + edge.value.weight

            if newDistance < (distances[edge.destination] ?? max) {
                // Negative cycle detected
                return ([:], [:])
            }
        }

        return (distances, predecessors)
    }
}
