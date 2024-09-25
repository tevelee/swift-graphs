extension MinimumSpanningTreeAlgorithm {
    /// Creates a Kruskal algorithm instance.
    /// - Returns: An instance of `KruskalAlgorithm`.
    @inlinable public static func kruskal<Node, Edge>() -> Self where Self == KruskalAlgorithm<Node, Edge> {
        KruskalAlgorithm()
    }
}

/// An implementation of the Kruskal algorithm for finding the minimum spanning tree in a graph.
public struct KruskalAlgorithm<Node: Hashable, Edge: Weighted>: MinimumSpanningTreeAlgorithm {
    /// Initializes a new `KruskalAlgorithm` instance.
    @inlinable public init() {}

    /// Finds the minimum spanning tree in the graph using the Kruskal algorithm.
    /// - Parameter graph: The graph in which to find the minimum spanning tree.
    /// - Returns: An array of `GraphEdge` instances representing the edges in the minimum spanning tree.
    @inlinable public func minimumSpanningTree(in graph: some WholeGraphProtocol<Node, Edge>) -> [GraphEdge<Node, Edge>] {
        let sortedEdges = graph.allEdges.sorted { $0.value.weight < $1.value.weight }
        let nodeCount = graph.allNodes.count

        var mst: [GraphEdge<Node, Edge>] = []
        var uf = UnionFind<Node>()
        for edge in sortedEdges {
            let source = edge.source
            let destination = edge.destination

            if uf.find(source) != uf.find(destination) {
                uf.union(source, destination)
                mst.append(edge)
            }

            if mst.count == nodeCount - 1 {
                break
            }
        }
        return mst
    }
}

/// A data structure for union-find (disjoint-set) operations.
public struct UnionFind<Node: Hashable> {
    /// A dictionary mapping each node to its parent node.
    @usableFromInline var parent: [Node: Node]

    /// Initializes a new `UnionFind` instance.
    @inlinable public init() {
        self.parent = [:]
    }

    /// Finds the representative (root) of the set containing the given node.
    /// - Parameter node: The node for which to find the representative.
    /// - Returns: The representative of the set containing the node.
    @inlinable public mutating func find(_ node: Node) -> Node {
        if parent[node] != node && parent[node] != nil {
            parent[node] = find(parent[node]!) // Path compression
        } else if parent[node] == nil {
            parent[node] = node
        }
        return parent[node]!
    }

    /// Unites the sets containing the two given nodes.
    /// - Parameters:
    ///   - node1: The first node.
    ///   - node2: The second node.
    @inlinable public mutating func union(_ node1: Node, _ node2: Node) {
        let root1 = find(node1)
        let root2 = find(node2)
        if root1 != root2 {
            parent[root2] = root1
        }
    }

    /// Adds a node to the Union-Find data structure.
    /// - Parameter node: The node to add.
    @inlinable public mutating func add(_ node: Node) {
        if parent[node] == nil {
            parent[node] = node
        }
    }
}
