import Collections

extension KShortestPathsAlgorithm {
    /// Creates a Yen's algorithm instance.
    /// - Returns: An instance of `YensAlgorithm`.
    @inlinable public static func yen<Node, Edge>() -> Self where Self == YensAlgorithm<Node, Edge> {
        .init()
    }
}

extension Graph {
    /// Finds the K shortest paths from the source node to the destination node in the graph using Yen's Algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - k: The number of shortest paths to find.
    /// - Returns: An array of `Path` instances representing the K shortest paths.
    @inlinable public func kShortestPaths(
        from source: Node,
        to destination: Node,
        k: Int
    ) -> [Path<Node, Edge>] where Node: Hashable, Edge: Weighted & Equatable, Edge.Weight: Numeric, Edge.Weight.Magnitude == Edge.Weight {
        kShortestPaths(from: source, to: destination, k: k, using: .yen())
    }
}

/// An implementation of Yen's Algorithm for finding the K shortest loopless paths between two nodes in a graph.
public struct YensAlgorithm<Node: Hashable, Edge: Weighted & Equatable>: KShortestPathsAlgorithm
where Edge.Weight: Numeric, Edge.Weight.Magnitude == Edge.Weight {
    /// Initializes a new `YensAlgorithm` instance.
    @inlinable public init() {}

    /// Finds the K shortest paths from the source node to the destination node in the graph using Yen's Algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - k: The number of shortest paths to find.
    ///   - graph: The graph in which to find the shortest paths.
    /// - Returns: An array of `Path` instances representing the K shortest paths.
    @inlinable public func kShortestPaths(
        from source: Node,
        to destination: Node,
        k: Int,
        in graph: some Graph<Node, Edge>
    ) -> [Path<Node, Edge>] {
        var a: [Path<Node, Edge>] = []
        var b: Heap<Path<Node, Edge>> = []

        // Step 1: Compute the shortest path from source to destination
        guard
            let shortestPath = graph.shortestPath(
                from: source,
                to: destination,
                using: .dijkstra()
            )
        else {
            // No path exists between source and destination
            return a
        }
        a.append(shortestPath)

        // Step 2: Loop to find up to k shortest paths
        for k_i in 1 ..< k {
            let previousPath = a[k_i - 1]
            let previousEdges = previousPath.edges

            for i in 0 ..< previousEdges.count {
                let spurNode = previousEdges[i].source
                let rootPathEdges = Array(previousEdges[0 ..< i])

                // Create a copy of the graph
                var tempGraph = DisjointGraph<Node, Edge>(nodes: graph.allNodes, edges: graph.allEdges)

                // Remove edges that are part of previous paths sharing the same root path
                for path in a {
                    let pathEdges = path.edges
                    if pathEdges.count > i, Array(pathEdges[0 ..< i]) == rootPathEdges {
                        let edgeToRemove = pathEdges[i]
                        tempGraph.removeEdge { $0 == edgeToRemove }
                    }
                }

                // Remove nodes in rootPath except spurNode
                let rootPathNodes = rootPathEdges.map { $0.source }
                for node in rootPathNodes where node != spurNode {
                    tempGraph.removeNode { $0 == node }
                }

                // Compute the spur path from spurNode to destination
                if let spurPath = DijkstraAlgorithm<Node, Edge>().shortestPath(
                    from: spurNode,
                    to: destination,
                    in: tempGraph
                ) {
                    // Total path is rootPath + spurPath
                    let totalEdges = rootPathEdges + spurPath.edges
                    let totalPath = Path(source: source, destination: destination, edges: totalEdges)

                    // Avoid duplicates
                    if !b.unordered.contains(totalPath) && !a.contains(totalPath) {
                        b.insert(totalPath)
                    }
                }
            }

            if b.isEmpty {
                break
            }

            // Add the path with the lowest cost from B to A
            guard let nextPath = b.popMin() else {
                break
            }
            a.append(nextPath)
        }

        return a
    }
}
