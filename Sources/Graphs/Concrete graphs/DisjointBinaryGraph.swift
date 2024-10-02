/// A binary graph structure that can represent multiple disconnected components.
public struct DisjointBinaryGraph<Node, Edge> {
    /// The nodes of the graph.
    @usableFromInline var _nodes: [Node]
    /// The edges of the binary graph.
    @usableFromInline var _edges: [BinaryGraphEdges<Node, Edge>]
    /// A closure to determine if two nodes are equal.
    public let isEqual: (Node, Node) -> Bool

    /// Initializes a new disjoint binary graph with the given edges and equality function.
    /// - Parameters:
    ///  - nodes: A list of `Node`s of the graph.
    ///  - edges: A list of `BinaryGraphEdges` representing the edges of the graph.
    ///  - isEqual: A closure that takes two nodes and returns a Boolean value indicating whether they are equal.
    @inlinable public init(
        nodes: some Sequence<Node>,
        edges: some Sequence<BinaryGraphEdges<Node, Edge>>,
        isEqual: @escaping (Node, Node) -> Bool
    ) {
        self._nodes = Array(nodes)
        self._edges = Array(edges)
        self.isEqual = isEqual
    }

    /// Initializes a new disjoint graph from a connected graph.
    /// - Parameter graph: A connected graph.
    @inlinable public init(from graph: ConnectedBinaryGraph<Node, Edge>) {
        self._nodes = graph.allNodes
        self._edges = graph._edges
        self.isEqual = graph.isEqual
    }
}

extension DisjointBinaryGraph: BinaryGraphComponent {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: A `BinaryGraphEdges` instance containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> BinaryGraphEdges<Node, Edge> {
        _edges.first { isEqual($0.source, node) } ?? BinaryGraphEdges(source: node, lhs: nil, rhs: nil)
    }
}

extension DisjointBinaryGraph: Graph {
    /// The nodes of the graph.
    @inlinable public var allNodes: [Node] {
        _nodes
    }

    /// The edges of the graph.
    @inlinable public var allEdges: [GraphEdge<Node, Edge>] {
        _edges.flatMap(\.elements)
    }
}

extension DisjointBinaryGraph: MutableGraphComponent {
    /// Adds an edge to the graph.
    /// - Parameter edge: The edge to add.
    @inlinable public mutating func addEdge(_ edge: GraphEdge<Node, Edge>) {
        if let index = _edges.firstIndex(where: { isEqual($0.source, edge.source) }) {
            var binaryEdges = _edges[index]
            if binaryEdges.lhs == nil {
                binaryEdges.lhs = edge
            } else if binaryEdges.rhs == nil {
                binaryEdges.rhs = edge
            } else {
                // Both lhs and rhs are occupied, cannot add more edges
                // You can handle this case as per your requirements
            }
            _edges[index] = binaryEdges
        } else {
            _edges.append(BinaryGraphEdges(source: edge.source, lhs: edge, rhs: nil))
        }
    }

    /// Removes edges from the graph that satisfy the given condition.
    /// - Parameter condition: A closure that takes an edge and returns a Boolean value indicating whether the edge should be removed.
    @inlinable public mutating func removeEdge(where condition: (GraphEdge<Node, Edge>) -> Bool) {
        for index in _edges.indices {
            var binaryEdges = _edges[index]
            if let lhs = binaryEdges.lhs, condition(lhs) {
                binaryEdges.lhs = nil
            }
            if let rhs = binaryEdges.rhs, condition(rhs) {
                binaryEdges.rhs = nil
            }
            _edges[index] = binaryEdges
        }
    }
}

extension DisjointBinaryGraph: MutableGraph {
    /// Adds a node to the graph.
    @inlinable public mutating func addNode(_ node: Node) {
        if !_nodes.contains(where: { isEqual($0, node) }) {
            _nodes.append(node)
        }
    }

    /// Removes nodes from the graph that satisfy the given condition.
    @inlinable public mutating func removeNode(where condition: (Node) -> Bool) {
        _nodes.removeAll(where: condition)
        _edges.removeAll {
            condition($0.source)
                || ($0.lhs.map { condition($0.destination) } ?? false)
                || ($0.rhs.map { condition($0.destination) } ?? false)
        }
    }
}
