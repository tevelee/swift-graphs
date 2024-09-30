/// A graph structure representing an undirected graph derived from a given base graph.
@dynamicMemberLookup
public struct UndirectedGraph<Base: Graph>: Graph where Base.Node: Hashable {
    public typealias Node = Base.Node
    public typealias Edge = Base.Edge

    /// The base graph from which the undirected graph is derived.
    @usableFromInline let base: Base
    /// An adjacency list representing the edges in the undirected graph.
    @usableFromInline var adjacencyList: [Node: [GraphEdge<Node, Edge>]] = [:]

    /// Initializes a new undirected graph with the given base graph.
    /// - Parameter base: The base graph from which the undirected graph is derived.
    @inlinable public init(base: Base) {
        self.base = base
        for edge in base.allEdges {
            adjacencyList[edge.destination, default: []].append(edge)
        }
    }

    /// Returns the edges originating from the specified node in the undirected graph.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges from the specified node in the undirected graph.
    public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        base.edges(from: node) + (adjacencyList[node] ?? [])
    }

    /// All edges in the undirected graph.
    /// - Note: This includes both the original and reversed edges from the base graph.
    public var allEdges: [GraphEdge<Node, Edge>] {
        base.allEdges + base.allEdges.map(\.reversed)
    }

    /// All nodes in the undirected graph.
    public var allNodes: [Base.Node] {
        base.allNodes
    }

    /// Subscript that accesses members on the underlying graph instance
    @inlinable public subscript<Member>(dynamicMember keyPath: KeyPath<Base, Member>) -> Member {
        base[keyPath: keyPath]
    }
}
