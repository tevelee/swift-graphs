extension ShortestPathsForAllPairsAlgorithm {
    /// Creates a Floyd-Warshall algorithm instance.
    /// - Returns: An instance of `FloydWarshallAlgorithm`.
    @inlinable public static func floydWarshall<Node, Edge>() -> Self
    where Self == FloydWarshallAlgorithm<Node, Edge>, Edge.Weight: FixedWidthInteger {
        .init(max: .max)
    }

    /// Creates a Floyd-Warshall algorithm instance.
    /// - Parameter max: The maximum weight of an edge in the graph.
    /// - Returns: An instance of `FloydWarshallAlgorithm`.
    @inlinable public static func floydWarshall<Node, Edge>(max: Edge.Weight) -> Self where Self == FloydWarshallAlgorithm<Node, Edge> {
        .init(max: max)
    }
}

extension Graph where Node: Hashable, Edge: Weighted, Edge.Weight: FixedWidthInteger {
    /// Finds the shortest paths between all pairs of nodes using the Floyd-Warshall algorithm.
    @inlinable public func shortestPathsForAllPairs() -> [Node: [Node: Edge.Weight]] {
        shortestPathsForAllPairs(using: .floydWarshall())
    }
}

/// An implementation of the Floyd-Warshall algorithm for finding the shortest paths between all pairs of nodes in a graph.
public struct FloydWarshallAlgorithm<Node: Hashable, Edge: Weighted>: ShortestPathsForAllPairsAlgorithm where Edge.Weight: Numeric {
    /// The maximum value possible for weight.
    public let max: Edge.Weight

    /// Initializes a new `FloydWarshallAlgorithm` instance.
    @inlinable public init(max: Edge.Weight) {
        self.max = max
    }

    /// Computes the shortest paths between all pairs of nodes in the graph using the Floyd-Warshall algorithm.
    @inlinable public func shortestPathsForAllPairs(in graph: some Graph<Node, Edge>) -> [Node: [Node: Edge.Weight]] {
        var distances: [Node: [Node: Edge.Weight]] = [:]

        // Initialize distances
        for u in graph.allNodes {
            distances[u] = [:]
            for v in graph.allNodes {
                if u == v {
                    distances[u]?[v] = .zero
                } else {
                    distances[u]?[v] = nil
                }
            }
        }

        for edge in graph.allEdges {
            distances[edge.source]?[edge.destination] = edge.value.weight
        }

        // Floyd-Warshall algorithm
        for k in graph.allNodes {
            for i in graph.allNodes {
                for j in graph.allNodes {
                    if let ik = distances[i]?[k], let kj = distances[k]?[j] {
                        let ij = distances[i]?[j] ?? max
                        let newDistance = ik + kj
                        if newDistance < ij {
                            distances[i]?[j] = newDistance
                        }
                    }
                }
            }
        }

        return distances
    }
}
