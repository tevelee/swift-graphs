import Algorithms

/// A binary graph structure that uses hashed values for nodes and can represent multiple disconnected components.
public struct DisjointBinaryHashGraph<Node: Hashable, Edge> {
    /// A dictionary mapping hashed values to the edges of the binary graph.
    @usableFromInline var _edges: [Node: BinaryGraphEdges<Node, Edge>]
    /// An array of nodes in the graph.
    @usableFromInline var _nodes: Set<Node>

    /// Initializes a new disjoint hashed binary graph with the given edges, hash function, and equality function.
    /// - Parameters:
    ///   - edges: An array of `BinaryGraphEdges` representing the edges of the graph.
    ///   - hashValue: A closure that takes a node and returns its hash value.
    ///   - isEqual: A closure that takes two nodes and returns a Boolean value indicating whether they are equal.
    @inlinable public init(
        edges: some Sequence<BinaryGraphEdges<Node, Edge>>
    ) {
        _edges = edges.keyed(by: \.source)
        _nodes = Set(edges.flatMap {
            [$0.source, $0.lhs?.destination, $0.rhs?.destination].compactMap(\.self)
        })
    }
}

extension DisjointBinaryHashGraph: GraphComponent {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        _edges[node].flatMap {
            [$0.lhs, $0.rhs].compactMap(\.self)
         } ?? []
    }
}

extension DisjointBinaryHashGraph: BinaryGraphComponent {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: A `BinaryGraphEdges` instance containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> BinaryGraphEdges<Node, Edge> {
        _edges[node] ?? BinaryGraphEdges(source: node, lhs: nil, rhs: nil)
    }
}

extension DisjointBinaryHashGraph: Graph {
    /// The edges of the graph.
    @inlinable public var allEdges: [GraphEdge<Node, Edge>] {
        _edges.flatMap {
            [$0.value.lhs, $0.value.rhs].compactMap(\.self)
        }
    }

    /// The nodes of the graph.
    @inlinable public var allNodes: [Node] {
        Array(_nodes)
    }
}

extension DisjointBinaryHashGraph: MutableGraphComponent {
    /// Adds an edge to the graph.
    /// - Parameter edge: The edge to add.
    @inlinable public mutating func addEdge(_ edge: GraphEdge<Node, Edge>) {
        var binaryEdges = _edges[edge.source] ?? BinaryGraphEdges(source: edge.source, lhs: nil, rhs: nil)
        if binaryEdges.lhs == nil {
            binaryEdges.lhs = edge
        } else if binaryEdges.rhs == nil {
            binaryEdges.rhs = edge
        } else {
            // Both lhs and rhs are occupied, cannot add more edges
        }
        _edges[edge.source] = binaryEdges
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

extension DisjointBinaryHashGraph: MutableGraph {
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
