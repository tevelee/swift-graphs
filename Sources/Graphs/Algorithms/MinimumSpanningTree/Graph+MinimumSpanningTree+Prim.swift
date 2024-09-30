import Collections

extension MinimumSpanningTreeAlgorithm {
    /// Creates a Prim algorithm instance.
    /// - Returns: An instance of `PrimAlgorithm`.
    @inlinable public static func prim<Node, Edge>() -> Self where Self == PrimAlgorithm<Node, Edge> {
        PrimAlgorithm()
    }
}

/// An implementation of the Prim algorithm for finding the minimum spanning tree in a graph.
public struct PrimAlgorithm<Node: Hashable, Edge: Weighted & Equatable>: MinimumSpanningTreeAlgorithm {
    /// Initializes a new `PrimAlgorithm` instance.
    @inlinable public init() {}

    /// Finds the minimum spanning tree in the graph using the Prim algorithm.
    /// - Parameter graph: The graph in which to find the minimum spanning tree.
    /// - Returns: An array of `GraphEdge` instances representing the edges in the minimum spanning tree.
    @inlinable public func minimumSpanningTree(in graph: some Graph<Node, Edge>) -> [GraphEdge<Node, Edge>] {
        guard let startNode = graph.allNodes.first else {
            return []
        }
        let nodeCount = graph.allNodes.count

        var mst: [GraphEdge<Node, Edge>] = []
        var visited: Set<Node> = [startNode]
        var heap = Heap<GraphEdge<Node, Edge>>()

        for edge in graph.edges(from: startNode) {
            heap.insert(edge)
        }

        while let edge = heap.popMin() {
            let destination = edge.destination
            if !visited.contains(destination) {
                visited.insert(destination)
                mst.append(edge)

                for nextEdge in graph.edges(from: destination) {
                    if !visited.contains(nextEdge.destination) {
                        heap.insert(nextEdge)
                    }
                }

                if visited.count == nodeCount {
                    break
                }
            }
        }

        return mst
    }
}
