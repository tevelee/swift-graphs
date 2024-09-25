/// A generic graph structure that holds nodes and edges.
public struct Graph<Node, Edge> {
    /// The edges of the graph.
    @usableFromInline let _edges: [GraphEdge<Node, Edge>]
    
    /// A closure to determine if two nodes are equal.
    @usableFromInline let isEqual: (Node, Node) -> Bool

    /// Initializes a new graph with the given edges and equality function.
    /// - Parameters:
    ///   - edges: An array of `GraphEdge` representing the edges of the graph.
    ///   - isEqual: A closure that takes two nodes and returns a Boolean value indicating whether they are equal.
    @inlinable public init(edges: [GraphEdge<Node, Edge>], isEqual: @escaping (Node, Node) -> Bool) {
        self._edges = edges
        self.isEqual = isEqual
    }
}

extension Graph: GraphProtocol {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        self._edges.filter { isEqual($0.source, node) }
    }
}

extension Graph: WholeGraphProtocol where Node: Hashable {
    /// All nodes in the graph.
    public var allNodes: [Node] {
        var nodes = Set<Node>()
        for edge in _edges {
            nodes.insert(edge.source)
            nodes.insert(edge.destination)
        }
        return Array(nodes)
    }

    /// All edges in the graph.
    public var allEdges: [GraphEdge<Node, Edge>] {
        _edges
    }
}

extension Graph where Node: Equatable {
    /// Initializes a new graph with the given edges.
    /// - Parameter edges: An array of `GraphEdge` representing the edges of the graph.
    @inlinable public init(edges: [GraphEdge<Node, Edge>]) {
        self.init(edges: edges, isEqual: ==)
    }

    /// Initializes a new graph with the given edges.
    /// - Parameter edges: A dictionary where the key is a node and the value is an array of destination nodes.
    @inlinable public init(edges: [Node: [Node]]) where Edge == Void {
        self.init(edges: edges.flatMap { source, destinations in
            destinations.map { GraphEdge(source: source, destination: $0) }
        }, isEqual: ==)
    }

    /// Initializes a new graph with the given edges and weights.
    /// - Parameter edges: A dictionary where the key is a node and the value is another dictionary
    ///   where the key is a destination node and the value is the edge weight.
    @inlinable public init(edges: [Node: [Node: Edge]]) where Node: Hashable {
        self.init(edges: edges.flatMap { source, destinations in
            destinations.map { GraphEdge(source: source, destination: $0, value: $1) }
        }, isEqual: ==)
    }
}
