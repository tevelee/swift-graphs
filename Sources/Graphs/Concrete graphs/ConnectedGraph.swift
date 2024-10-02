/// A generic graph structure that holds nodes and edges.
public struct ConnectedGraph<Node, Edge> {
    /// The edges of the graph.
    @usableFromInline let _edges: [GraphEdge<Node, Edge>]

    /// A closure to determine if two nodes are equal.
    public let isEqual: (Node, Node) -> Bool

    /// Internal store to cache the results of expensive operations
    @usableFromInline class Cache {
        /// Space to cache all nodes once computed
        @usableFromInline var allNodes: [Node]?
    }
    /// Internal store to cache the results of expensive operations
    @usableFromInline var cache = Cache()

    /// Initializes a new graph with the given edges and equality function.
    /// - Parameters:
    ///   - edges: A list of `GraphEdge` representing the edges of the graph.
    ///   - isEqual: A closure that takes two nodes and returns a Boolean value indicating whether they are equal.
    @inlinable public init(edges: some Sequence<GraphEdge<Node, Edge>>, isEqual: @escaping (Node, Node) -> Bool) {
        self._edges = Array(edges)
        self.isEqual = isEqual
    }
}

extension ConnectedGraph: GraphComponent {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        _edges.filter { isEqual($0.source, node) }
    }
}

extension ConnectedGraph: Graph {
    /// All nodes in the graph. Cached, O(n^2) to compute.
    @inlinable public var allNodes: [Node] {
        if let cached = cache.allNodes {
            return cached
        }
        let nodes = computeAllNodes()
        cache.allNodes = nodes
        return nodes
    }

    /// All nodes in the graph. O(n^2)
    @usableFromInline func computeAllNodes() -> [Node] {
        var nodes: [Node] = []
        for edge in _edges {
            if !nodes.contains(where: { isEqual($0, edge.source) }) {
                nodes.append(edge.source)
            }
            if !nodes.contains(where: { isEqual($0, edge.destination) }) {
                nodes.append(edge.destination)
            }
        }
        return nodes
    }

    /// All edges in the graph.
    @inlinable public var allEdges: [GraphEdge<Node, Edge>] {
        _edges
    }
}

extension ConnectedGraph where Node: Hashable {
    /// All nodes in the graph. Cached, O(n) to compute.
    @inlinable public var allNodes: [Node] {
        if let cached = cache.allNodes {
            return cached
        }
        let nodes = computeAllNodes()
        cache.allNodes = nodes
        return nodes
    }

    /// All nodes in the graph. O(n)
    @usableFromInline func computeAllNodes() -> [Node] {
        var nodes: Set<Node> = []
        for edge in _edges {
            nodes.insert(edge.source)
            nodes.insert(edge.destination)
        }
        return Array(nodes)
    }
}

extension ConnectedGraph where Node: Equatable {
    /// Initializes a new graph with the given edges.
    /// - Parameter edges: A list of `GraphEdge` representing the edges of the graph.
    @inlinable public init(edges: some Sequence<GraphEdge<Node, Edge>>) {
        self.init(edges: edges, isEqual: ==)
    }

    /// Initializes a new graph with the given edges.
    /// - Parameter edges: A dictionary where the key is a node and the value is a list of destination nodes.
    @inlinable public init(edges: [Node: some Sequence<Node>]) where Edge == Empty {
        self.init(
            edges: edges.flatMap { source, destinations in
                destinations.map { GraphEdge(source: source, destination: $0) }
            },
            isEqual: ==
        )
    }

    /// Initializes a new graph with the given edges and weights.
    /// - Parameter edges: A dictionary where the key is a node and the value is another dictionary
    ///   where the key is a destination node and the value is the edge weight.
    @inlinable public init(edges: [Node: [Node: Edge]]) where Node: Hashable {
        self.init(
            edges: edges.flatMap { source, destinations in
                destinations.map { GraphEdge(source: source, destination: $0, value: $1) }
            },
            isEqual: ==
        )
    }
}
