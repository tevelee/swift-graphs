/// A binary graph structure that uses hashed values for nodes to efficiently store and retrieve edges.
public struct ConnectedBinaryHashGraph<Node, Edge, HashValue: Hashable> {
    /// A dictionary mapping hashed values to the edges of the binary graph.
    @usableFromInline let _edges: [HashValue: BinaryGraphEdges<Node, Edge>]
    /// A closure to compute the hash value of a node.
    public let hashValue: (Node) -> HashValue

    /// Initializes a new hashed binary graph with the given edges and hash function.
    /// - Parameters:
    ///   - edges: An array of `BinaryGraphEdges` representing the edges of the graph.
    ///   - hashValue: A closure that takes a node and returns its hash value.
    public init(edges: [BinaryGraphEdges<Node, Edge>], hashValue: @escaping (Node) -> HashValue) {
        self._edges = edges.keyed { hashValue($0.source) }
        self.hashValue = hashValue
    }
}

extension ConnectedBinaryHashGraph {
    /// Initializes a disjoint graph with the same nodes and edges.
    @inlinable public func makeDisjoint() -> DisjointBinaryHashGraph<Node, Edge, HashValue> {
        .init(nodes: allNodes, edges: _edges.values, hashValue: hashValue)
    }
}

extension ConnectedBinaryHashGraph: BinaryGraphComponent {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: A `BinaryGraphEdges` instance containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> BinaryGraphEdges<Node, Edge> {
        _edges[hashValue(node)] ?? BinaryGraphEdges(source: node, lhs: nil, rhs: nil)
    }
}

extension ConnectedBinaryHashGraph: Graph {
    /// All nodes in the graph.
    @inlinable public var allNodes: [Node] {
        var nodes: [HashValue: Node] = [:]
        for (_, edges) in _edges {
            nodes[hashValue(edges.source)] = edges.source
            if let node = edges.lhs?.destination {
                nodes[hashValue(node)] = node
            }
            if let node = edges.rhs?.destination {
                nodes[hashValue(node)] = node
            }
        }
        return Array(nodes.values)
    }

    /// All edges in the binary graph.
    @inlinable public var allEdges: [GraphEdge<Node, Edge>] {
        _edges.values.compactMap(\.lhs) + _edges.values.compactMap(\.rhs)
    }
}

extension ConnectedBinaryHashGraph where HashValue == Node {
    /// Initializes a new hashed binary graph with the given edges.
    /// - Parameter edges: An array of `BinaryGraphEdges` representing the edges of the graph.
    @inlinable public init(edges: [BinaryGraphEdges<Node, Edge>]) {
        self.init(edges: edges, hashValue: { $0 })
    }

    /// Initializes a new hashed binary graph with the given edges.
    /// - Parameter edges: A dictionary where the key is a node and the value is a tuple containing the left-hand side and right-hand side nodes.
    @inlinable public init(edges: [Node: (lhs: Node?, rhs: Node?)?]) where Node: Hashable, Edge == Empty {
        self.init(
            edges: edges.map { source, destinations in
                BinaryGraphEdges(
                    source: source,
                    lhs: destinations?.lhs.map { GraphEdge(source: source, destination: $0) },
                    rhs: destinations?.rhs.map { GraphEdge(source: source, destination: $0) }
                )
            },
            hashValue: { $0 }
        )
    }
}
