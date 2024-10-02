import Algorithms

/// A hash-based graph structure that can represent multiple disconnected components efficiently.
public struct DisjointHashGraph<Node: Hashable, Edge> {
    /// A dictionary mapping hashed values to the edges of the graph.
    @usableFromInline var _edges: [Node: [GraphEdge<Node, Edge>]]
    /// An array of nodes in the graph.
    @usableFromInline var _nodes: Set<Node>

    /// Initializes a new disjoint hash graph with the given edges, nodes, hash function, and equality function.
    /// - Parameters:
    ///   - edges: A dictionary mapping hashed values to arrays of `GraphEdge` instances.
    ///   - nodes: An array of nodes in the graph.
    @inlinable public init(
        edges: [Node: some Sequence<GraphEdge<Node, Edge>>],
        nodes: some Sequence<Node>
    ) {
        self._edges = edges.mapValues(Array.init)
        self._nodes = Set(nodes)
    }

    /// Initializes a new disjoint hash graph with the given edges and hash function.
    /// - Parameters:
    ///   - edges: An array of `GraphEdge` instances.
    @inlinable public init(
        edges: some Sequence<GraphEdge<Node, Edge>>
    ) {
        self._edges = edges.grouped(by: \.source)
        self._nodes = Set(edges.flatMap {
            [$0.source, $0.destination]
        })
    }
}

extension DisjointHashGraph: GraphComponent {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        _edges[node] ?? []
    }
}

extension DisjointHashGraph: Graph {
    /// All nodes in the graph.
    @inlinable public var allNodes: [Node] {
        Array(_nodes)
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
        addNode(edge.source)
        addNode(edge.destination)
        _edges[edge.source, default: []].append(edge)
    }

    /// Removes edges from the graph that satisfy the given condition.
    /// - Parameter condition: A closure that takes an edge and returns a Boolean value indicating whether the edge should be removed.
    @inlinable public mutating func removeEdge(where condition: (GraphEdge<Node, Edge>) -> Bool) {
        for key in _edges.keys {
            _edges[key]?.removeAll(where: condition)
        }
    }
}

extension DisjointHashGraph: MutableGraph {
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
