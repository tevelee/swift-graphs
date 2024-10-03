/// A generic graph structure that can represent multiple disconnected components.
public struct DisjointGraph<Node, Edge> {
    /// The nodes of the graph.
    @usableFromInline var _nodes: [Node]
    /// The edges of the graph.
    @usableFromInline var _edges: [GraphEdge<Node, Edge>]
    /// A closure to determine if two nodes are equal.
    public let isEqual: (Node, Node) -> Bool

    /// Initializes a new disjoint graph with the given nodes, edges, and equality function.
    /// - Parameters:
    ///   - nodes: An array of nodes in the graph.
    ///   - edges: An array of `GraphEdge` representing the edges of the graph.
    ///   - isEqual: A closure that takes two nodes and returns a Boolean value indicating whether they are equal.
    @inlinable public init(nodes: some Sequence<Node>, edges: some Sequence<GraphEdge<Node, Edge>>, isEqual: @escaping (Node, Node) -> Bool) {
        self._nodes = Array(nodes)
        self._edges = Array(edges)
        self.isEqual = isEqual
    }

    /// Initializes a new disjoint graph from a connected graph.
    /// - Parameter graph: A connected graph.
    @inlinable public init(from graph: ConnectedGraph<Node, Edge>) {
        self._nodes = graph.allNodes
        self._edges = graph.allEdges
        self.isEqual = graph.isEqual
    }
}

extension DisjointGraph: GraphComponent {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        _edges.filter { isEqual($0.source, node) }
    }
}

extension DisjointGraph: Graph {
    /// All nodes in the graph.
    @inlinable public var allNodes: [Node] {
        _nodes
    }

    /// All edges in the graph.
    @inlinable public var allEdges: [GraphEdge<Node, Edge>] {
        _edges
    }
}

extension DisjointGraph: MutableGraphComponent {
    /// Adds a node to the graph.
    /// - Parameter node: The node to add.
    @inlinable public mutating func addNode(_ node: Node) {
        if !_nodes.contains(where: { isEqual($0, node) }) {
            _nodes.append(node)
        }
    }

    /// Removes nodes from the graph that satisfy the given condition.
    /// - Parameter condition: A closure that takes a node and returns a Boolean value indicating whether the node should be removed.
    @inlinable public mutating func removeNode(where condition: (Node) -> Bool) {
        _nodes.removeAll(where: condition)
        // Remove edges connected to the removed nodes
        _edges.removeAll { edge in
            condition(edge.source) || condition(edge.destination)
        }
    }
}

extension DisjointGraph: MutableGraph {
    /// Adds an edge to the graph.
    /// - Parameter edge: The edge to add.
    @inlinable public mutating func addEdge(_ edge: GraphEdge<Node, Edge>) {
        _edges.append(edge)
        addNode(edge.source)
        addNode(edge.destination)
    }

    /// Removes edges from the graph that satisfy the given condition.
    /// - Parameter condition: A closure that takes an edge and returns a Boolean value indicating whether the edge should be removed.
    @inlinable public mutating func removeEdge(where condition: (GraphEdge<Node, Edge>) -> Bool) {
        _edges.removeAll(where: condition)
    }
}

extension DisjointGraph where Node: Equatable {
    /// Initializes a new disjoint graph with the given nodes and edges.
    /// - Parameters:
    ///   - nodes: An array of nodes in the graph.
    ///   - edges: An array of `GraphEdge` representing the edges of the graph.
    @inlinable public init(nodes: some Sequence<Node>, edges: some Sequence<GraphEdge<Node, Edge>>) {
        self.init(nodes: nodes, edges: edges, isEqual: ==)
    }
}
