/// A binary graph structure that holds nodes and edges.
public struct BinaryGraph<Node, Edge> {
    /// The edges of the binary graph.
    @usableFromInline let _edges: [BinaryGraphEdges<Node, Edge>]
    
    /// A closure to determine if two nodes are equal.
    @usableFromInline let isEqual: (Node, Node) -> Bool

    /// Initializes a new binary graph with the given edges and equality function.
    /// - Parameters:
    ///   - edges: An array of `BinaryGraphEdges` representing the edges of the graph.
    ///   - isEqual: A closure that takes two nodes and returns a Boolean value indicating whether they are equal.
    @inlinable public init(edges: [BinaryGraphEdges<Node, Edge>], isEqual: @escaping (Node, Node) -> Bool) {
        self._edges = edges
        self.isEqual = isEqual
    }
}

extension BinaryGraph: BinaryGraphProtocol {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: A `BinaryGraphEdges` instance containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> BinaryGraphEdges<Node, Edge> {
        _edges.first { isEqual($0.source, node) } ?? BinaryGraphEdges(source: node, lhs: nil, rhs: nil)
    }
}

extension BinaryGraph: WholeGraphProtocol where Node: Hashable {
    /// All nodes in the binary graph.
    public var allNodes: [Node] {
        var nodes = Set<Node>()
        for edge in _edges {
            nodes.insert(edge.source)
            if let node = edge.lhs?.destination {
                nodes.insert(node)
            }
            if let node = edge.rhs?.destination {
                nodes.insert(node)
            }
        }
        return Array(nodes)
    }

    /// All edges in the binary graph.
    public var allEdges: [GraphEdge<Node, Edge>] {
        _edges.compactMap(\.lhs) + _edges.compactMap(\.rhs)
    }
}

extension BinaryGraph where Node: Equatable {
    /// Initializes a new binary graph with the given edges.
    /// - Parameter edges: An array of `BinaryGraphEdges` representing the edges of the graph.
    @inlinable public init(edges: [BinaryGraphEdges<Node, Edge>]) {
        self.init(edges: edges, isEqual: ==)
    }

    /// Initializes a new binary graph with the given edges.
    /// - Parameter edges: A dictionary where the key is a node and the value is a tuple containing the left-hand side and right-hand side nodes.
    @inlinable public init(edges: [Node: (lhs: Node?, rhs: Node?)?]) where Edge == Void {
        self.init(
            edges: edges.map { source, destinations in
                BinaryGraphEdges(
                    source: source,
                    lhs: destinations?.lhs.map { GraphEdge(source: source, destination: $0) },
                    rhs: destinations?.rhs.map { GraphEdge(source: source, destination: $0) }
                )
            },
            isEqual: ==
        )
    }
}
