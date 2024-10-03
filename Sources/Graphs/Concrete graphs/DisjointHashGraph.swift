import Algorithms

/// A hash-based graph structure that can represent multiple disconnected components efficiently.
public struct DisjointHashGraph<Node, Edge, HashValue: Hashable> {
    /// A dictionary mapping hashed values to the edges of the graph.
    @usableFromInline var _edges: [HashValue: [GraphEdge<Node, Edge>]]
    /// An array of nodes in the graph.
    @usableFromInline var _nodes: Set<HashValue>
    /// A closure to compute the hash value of a node.
    public let hashValue: (Node) -> HashValue

    /// Initializes a new disjoint hash graph with the given edges, nodes, hash function, and equality function.
    /// - Parameters:
    ///   - nodes: An array of nodes in the graph.
    ///   - edges: A dictionary mapping hashed values to arrays of `GraphEdge` instances.
    ///   - hashValue: A closure that takes a node and returns its hash value.
    @inlinable public init(
        nodes: some Sequence<Node>,
        edges: some Sequence<GraphEdge<Node, Edge>>,
        hashValue: @escaping (Node) -> HashValue
    ) {
        self._nodes = Set(nodes.map(hashValue))
        self._edges = edges.grouped { hashValue($0.source) }
        self.hashValue = hashValue
    }

    /// Initializes a new disjoint hash graph with the given edges and hash function.
    /// - Parameters:
    ///  - edges: An array of `GraphEdge` instances.
    ///  - hashValue: A closure that takes a node and returns its hash value.
    @inlinable public init(
        edges: some Sequence<GraphEdge<Node, Edge>>,
        hashValue: @escaping (Node) -> HashValue
    ) {
        self._edges = edges.grouped { hashValue($0.source) }
        self._nodes = Set(
            edges.flatMap {
                [hashValue($0.source), hashValue($0.destination)]
            }
        )
        self.hashValue = hashValue
    }
}

extension DisjointHashGraph: GraphComponent {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        _edges[hashValue(node)] ?? []
    }
}

extension DisjointHashGraph: Graph {
    /// All nodes in the graph.
    @inlinable public var allNodes: [Node] {
        var map: [HashValue: Node] = [:]
        for edge in allEdges {
            map[hashValue(edge.source)] = edge.source
            map[hashValue(edge.destination)] = edge.destination
        }
        return Array(map.values)
    }

    /// All edges in the graph.
    @inlinable public var allEdges: [GraphEdge<Node, Edge>] {
        _edges.values.flatMap { $0 }
    }
}

extension DisjointHashGraph: MutableGraphComponent {
    /// Adds an edge to the graph.
    /// - Parameter edge: The edge to add.
    @inlinable public mutating func addEdge(_ edge: GraphEdge<Node, Edge>) {
        _nodes.insert(hashValue(edge.source))
        _nodes.insert(hashValue(edge.destination))
        _edges[hashValue(edge.source), default: []].append(edge)
    }

    /// Removes edges from the graph that satisfy the given condition.
    /// - Parameter condition: A closure that takes an edge and returns a Boolean value indicating whether the edge should be removed.
    @inlinable public mutating func removeEdge(where condition: (GraphEdge<Node, Edge>) -> Bool) {
        for key in _edges.keys {
            _edges[key]?.removeAll(where: condition)
        }
    }
}

extension DisjointHashGraph: MutableGraph where HashValue == Node {
    /// Adds a node to the graph.
    /// - Parameter node: The node to add.
    @inlinable public mutating func addNode(_ node: Node) {
        _nodes.insert(node)
    }

    /// Removes nodes from the graph that satisfy the given condition.
    /// - Parameter condition: A closure that takes a node and returns a Boolean value indicating whether the node should be removed.
    @inlinable public mutating func removeNode(where condition: (Node) -> Bool) {
        for node in _nodes where condition(node) {
            _nodes.remove(node)
        }
        for key in _edges.keys {
            _edges[key]?.removeAll { condition($0.source) || condition($0.destination) }
        }
    }
}

extension DisjointHashGraph where Node: Hashable, HashValue == Node {
    /// Initializes a new hashed graph with the given edges.
    /// - Parameters:
    ///  - nodes: A list of `Node`s of the graph.
    ///  - edges: An array of `GraphEdge` instances.
    @inlinable public init(nodes: some Sequence<Node>, edges: some Sequence<GraphEdge<Node, Edge>>) {
        self.init(nodes: nodes, edges: edges, hashValue: { $0 })
    }
}
