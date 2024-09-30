extension ShortestPathsForAllPairsAlgorithm {
    /// Creates a new Johnson's algorithm instance with the specified edge weight function.
    /// - Parameter edge: A function that returns an edge with the specified weight.
    /// - Returns: An instance of `JohnsonAlgorithm`.
    @inlinable public static func johnson<Node, Edge>(edge: @escaping (Edge.Weight) -> Edge) -> Self where Self == JohnsonAlgorithm<Node, Edge> {
        .init(edge: edge)
    }
}

/// An implementation of Johnson's algorithm for finding the shortest paths between all pairs of nodes in a graph.
public struct JohnsonAlgorithm<Node: Hashable & Comparable, Edge: Weighted>: ShortestPathsForAllPairsAlgorithm where Edge.Weight: FixedWidthInteger, Edge.Weight.Magnitude == Edge.Weight {
    /// A function that returns an edge with the specified weight.
    @usableFromInline let edge: (Edge.Weight) -> Edge

    /// Initializes a new `JohnsonAlgorithm` instance with the specified edge weight function.
    @inlinable public init(edge: @escaping (Edge.Weight) -> Edge) {
        self.edge = edge
    }

    /// Computes the shortest paths between all pairs of nodes in the graph using Johnson's algorithm.
    @usableFromInline enum JohnsonNode: Hashable & Comparable {
        case original(Node)
        case q

        @inlinable static func < (lhs: JohnsonNode, rhs: JohnsonNode) -> Bool {
            switch (lhs, rhs) {
            case (.original(let a), .original(let b)):
                return a < b
            case (.original, .q):
                return true
            case (.q, .original):
                return false
            case (.q, .q):
                return false
            }
        }
    }

    /// Computes the shortest paths between all pairs of nodes in the graph using Johnson's algorithm.
    @inlinable public func shortestPathsForAllPairs(in graph: some Graph<Node, Edge>) -> [Node: [Node: Edge.Weight]] {
        // Step 1: Wrap nodes and create a unique node 'q'
        let q = JohnsonNode.q
        let originalNodes = graph.allNodes.map { JohnsonNode.original($0) }

        // Step 2: Create extended graph with edges from 'q' to all other nodes
        var extendedEdges: [GraphEdge<JohnsonNode, Edge>] = graph.allEdges.map { edge in
            GraphEdge(
                source: JohnsonNode.original(edge.source),
                destination: JohnsonNode.original(edge.destination),
                value: edge.value
            )
        }
        for node in originalNodes {
            extendedEdges.append(GraphEdge(source: q, destination: node, value: edge(.zero)))
        }

        // Step 3: Run Bellman-Ford from 'q'
        let extendedGraph = AdjacencyListGraph(edges: extendedEdges)
        let bellmanFord = BellmanFordAlgorithm<JohnsonNode, Edge>(max: Edge.Weight.max)
        let bellmanFordResult = bellmanFord.computeShortestPaths(from: q, in: extendedGraph)

        if bellmanFordResult.distances.isEmpty {
            return [:] // Negative cycle detected
        }
        let h = bellmanFordResult.distances

        // Step 4: Re-weight the edges
        var reweightedEdges: [GraphEdge<JohnsonNode, Edge>] = []
        for edge in extendedEdges {
            // Skip edges originating from 'q'
            if edge.source == q { continue }
            let newWeight = edge.value.weight + h[edge.source]! - h[edge.destination]!
            reweightedEdges.append(GraphEdge(source: edge.source, destination: edge.destination, value: self.edge(newWeight)))
        }

        let reweightedGraph = AdjacencyListGraph(edges: reweightedEdges)

        // Step 5: Run Dijkstra's algorithm from each node
        var distances: [Node: [Node: Edge.Weight]] = [:]
        let dijkstra = DijkstraAlgorithm<JohnsonNode, Edge>()

        for node in originalNodes {
            let result = dijkstra.computeShortestPaths(from: node, in: reweightedGraph)
            var nodeDistances: [Node: Edge.Weight] = [:]
            for (dest, dist) in result.costs {
                // Exclude paths involving 'q'
                if case .original(let originalDest) = dest {
                    nodeDistances[originalDest] = dist - h[node]! + h[dest]!
                }
            }
            if case .original(let originalNode) = node {
                distances[originalNode] = nodeDistances
            }
        }

        return distances
    }
}
