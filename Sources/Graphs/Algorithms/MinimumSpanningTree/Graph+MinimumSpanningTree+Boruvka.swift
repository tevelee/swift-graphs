extension MinimumSpanningTreeAlgorithm {
    /// Creates a Boruvka algorithm instance.
    /// - Returns: An instance of `BoruvkaAlgorithm`.
    @inlinable public static func boruvka<Node, Edge>() -> Self where Self == BoruvkaAlgorithm<Node, Edge> {
        BoruvkaAlgorithm()
    }
}

/// An implementation of the Boruvka algorithm for finding the minimum spanning tree in a graph.
public struct BoruvkaAlgorithm<Node: Hashable, Edge: Weighted>: MinimumSpanningTreeAlgorithm where Edge.Weight: Comparable {
    /// Initializes a new `BoruvkaAlgorithm` instance.
    @inlinable public init() {}

    /// Finds the minimum spanning tree in the graph using the Boruvka algorithm.
    /// - Parameter graph: The graph in which to find the minimum spanning tree.
    /// - Returns: An array of `GraphEdge` instances representing the edges in the minimum spanning tree.
    @inlinable public func minimumSpanningTree(in graph: some Graph<Node, Edge>) -> [GraphEdge<Node, Edge>] {
        var uf = UnionFind<Node>()
        var mst: [GraphEdge<Node, Edge>] = []

        for node in graph.allNodes {
            uf.add(node)
        }

        var numComponents = graph.allNodes.count

        while numComponents > 1 {
            var cheapest: [Node: GraphEdge<Node, Edge>] = [:]

            // Find cheapest edge for each component
            for edge in graph.allEdges {
                let u = edge.source
                let v = edge.destination
                let setU = uf.find(u)
                let setV = uf.find(v)

                if setU != setV {
                    if let currentEdge = cheapest[setU] {
                        if edge.value.weight < currentEdge.value.weight {
                            cheapest[setU] = edge
                        }
                    } else {
                        cheapest[setU] = edge
                    }
                    if let currentEdge = cheapest[setV] {
                        if edge.value.weight < currentEdge.value.weight {
                            cheapest[setV] = edge
                        }
                    } else {
                        cheapest[setV] = edge
                    }
                }
            }

            for (_, edge) in cheapest {
                let u = edge.source
                let v = edge.destination
                let setU = uf.find(u)
                let setV = uf.find(v)

                if setU != setV {
                    mst.append(edge)
                    uf.union(u, v)
                    numComponents -= 1
                }
            }
        }

        return mst
    }
}
