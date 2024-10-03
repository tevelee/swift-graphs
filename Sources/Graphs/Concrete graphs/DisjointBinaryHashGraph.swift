import Algorithms

/// A binary graph structure that uses hashed values for nodes and can represent multiple disconnected components.
public struct DisjointBinaryHashGraph<Node, Edge, HashValue: Hashable> {
    /// A dictionary mapping hashed values to the edges of the binary graph.
    @usableFromInline var _edges: [HashValue: BinaryGraphEdges<Node, Edge>]
    /// An array of nodes in the graph.
    @usableFromInline var _nodes: Set<HashValue>
    /// A closure to compute the hash value of a node.
    public let hashValue: (Node) -> HashValue

    /// Initializes a new disjoint hashed binary graph with the given edges, hash function, and equality function.
    /// - Parameters:
    ///  - nodes: A list of `Node`s of the graph.
    ///  - edges: An array of `BinaryGraphEdges` representing the edges of the graph.
    ///  - hashValue: A closure that takes a node and returns its hash value.
    @inlinable public init(
        nodes: some Sequence<Node>,
        edges: some Sequence<BinaryGraphEdges<Node, Edge>>,
        hashValue: @escaping (Node) -> HashValue
    ) {
        _nodes = Set(nodes.map(hashValue))
        _edges = edges.keyed { hashValue($0.source) }
        self.hashValue = hashValue
    }

    /// Initializes a new disjoint hashed binary graph with the given edges, hash function, and equality function.
    /// - Parameters:
    ///   - edges: An array of `BinaryGraphEdges` representing the edges of the graph.
    ///   - hashValue: A closure that takes a node and returns its hash value.
    @inlinable public init(
        edges: some Sequence<BinaryGraphEdges<Node, Edge>>,
        hashValue: @escaping (Node) -> HashValue
    ) {
        _edges = edges.keyed { hashValue($0.source) }
        _nodes = Set(
            edges.flatMap {
                [$0.source, $0.lhs?.destination, $0.rhs?.destination]
                    .compactMap { $0 }
                    .map(hashValue)
            }
        )
        self.hashValue = hashValue
    }
}

extension DisjointBinaryHashGraph: GraphComponent {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        _edges[hashValue(node)].flatMap {
            [$0.lhs, $0.rhs].compactMap { $0 }
        } ?? []
    }
}

extension DisjointBinaryHashGraph: BinaryGraphComponent {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: A `BinaryGraphEdges` instance containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> BinaryGraphEdges<Node, Edge> {
        _edges[hashValue(node)] ?? BinaryGraphEdges(source: node, lhs: nil, rhs: nil)
    }
}

extension DisjointBinaryHashGraph: Graph {
    /// The edges of the graph.
    @inlinable public var allEdges: [GraphEdge<Node, Edge>] {
        _edges.flatMap {
            [$0.value.lhs, $0.value.rhs].compactMap { $0 }
        }
    }

    /// The nodes of the graph.
    @inlinable public var allNodes: [Node] {
        var map: [HashValue: Node] = [:]
        for edge in allEdges {
            map[hashValue(edge.source)] = edge.source
            map[hashValue(edge.destination)] = edge.destination
        }
        return Array(map.values)
    }
}

extension DisjointBinaryHashGraph: MutableGraphComponent {
    /// Adds an edge to the graph.
    /// - Parameter edge: The edge to add.
    @inlinable public mutating func addEdge(_ edge: GraphEdge<Node, Edge>) {
        var binaryEdges = _edges[hashValue(edge.source)] ?? BinaryGraphEdges(source: edge.source, lhs: nil, rhs: nil)
        if binaryEdges.lhs == nil {
            binaryEdges.lhs = edge
        } else if binaryEdges.rhs == nil {
            binaryEdges.rhs = edge
        } else {
            // Both lhs and rhs are occupied, cannot add more edges
        }
        _edges[hashValue(edge.source)] = binaryEdges
    }

    /// Removes edges from the graph that satisfy the given condition.
    /// - Parameter condition: A closure that takes an edge and returns a Boolean value indicating whether the edge should be removed.
    @inlinable public mutating func removeEdge(where condition: (GraphEdge<Node, Edge>) -> Bool) {
        for key in _edges.keys {
            var binaryEdges = _edges[key]!
            if let lhs = binaryEdges.lhs, condition(lhs) {
                binaryEdges.lhs = nil
            }
            if let rhs = binaryEdges.rhs, condition(rhs) {
                binaryEdges.rhs = nil
            }
            _edges[key] = binaryEdges
        }
    }
}

extension DisjointBinaryHashGraph: MutableGraph where HashValue == Node {
    /// Adds a node to the graph.
    @inlinable public mutating func addNode(_ node: Node) {
        _nodes.insert(node)
    }

    /// Removes a node from the graph.
    @inlinable public mutating func removeNode(where condition: (Node) -> Bool) {
        for node in _nodes where condition(node) {
            _nodes.remove(node)
        }
        removeEdge { condition($0.source) || condition($0.destination) }
    }
}

extension DisjointBinaryHashGraph where HashValue == Node {
    /// Initializes a new hashed binary graph with the given edges.
    /// - Parameters:
    ///  - nodes: A list of `Node`s of the graph.
    ///  - edges: An array of `BinaryGraphEdges` representing the edges of the graph.
    @inlinable public init(nodes: some Sequence<Node>, edges: some Sequence<BinaryGraphEdges<Node, Edge>>) {
        self.init(nodes: nodes, edges: edges, hashValue: { $0 })
    }
}
