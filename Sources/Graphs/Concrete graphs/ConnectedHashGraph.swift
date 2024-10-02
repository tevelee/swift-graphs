import Algorithms

/// A graph structure that uses hashed values for nodes to efficiently store and retrieve edges.
public struct ConnectedHashGraph<Node, Edge, HashValue: Hashable> {
    /// A dictionary mapping hashed values to the edges of the graph.
    @usableFromInline let _edges: [HashValue: [GraphEdge<Node, Edge>]]
    /// A closure to compute the hash value of a node.
    public let hashValue: (Node) -> HashValue

    /// Initializes a new hashed graph with the given edges and hash function.
    /// - Parameters:
    ///   - edges: A dictionary mapping hashed values to arrays of `GraphEdge` instances.
    ///   - hashValue: A closure that takes a node and returns its hash value.
    @inlinable public init(edges: [HashValue: [GraphEdge<Node, Edge>]], hashValue: @escaping (Node) -> HashValue) {
        self._edges = edges
        self.hashValue = hashValue
    }

    /// Initializes a new hashed graph with the given edges and hash function.
    /// - Parameters:
    ///   - edges: An array of `GraphEdge` instances.
    ///   - hashValue: A closure that takes a node and returns its hash value.
    @inlinable public init(edges: [GraphEdge<Node, Edge>], hashValue: @escaping (Node) -> HashValue) {
        self._edges = edges.grouped { hashValue($0.source) }
        self.hashValue = hashValue
    }
}

extension ConnectedHashGraph: GraphComponent {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        self._edges[hashValue(node)] ?? []
    }
}

extension ConnectedHashGraph: Graph {
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

extension ConnectedHashGraph where Node: Hashable, HashValue == Node {
    /// Initializes a new hashed graph with the given edges.
    /// - Parameter edges: An array of `GraphEdge` instances.
    @inlinable public init(edges: [GraphEdge<Node, Edge>]) {
        self.init(edges: edges, hashValue: { $0 })
    }

    /// Initializes a new hashed graph with the given edges.
    /// - Parameter edges: A dictionary mapping nodes to arrays of destination nodes.
    @inlinable public init(edges: [Node: [Node]]) where Edge == Empty {
        self.init(
            edges: edges.flatMap { source, destinations in
                destinations.map { GraphEdge(source: source, destination: $0) }
            }.grouped(by: \.source),
            hashValue: { $0 }
        )
    }
}
