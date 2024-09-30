/// A graph structure representing the transpose of a given base graph.
@dynamicMemberLookup
public struct TransposedGraph<Base: Graph>: Graph where Base.Node: Hashable {
    public typealias Node = Base.Node
    public typealias Edge = Base.Edge

    /// The base graph from which the transpose is derived.
    public let base: Base
    /// An adjacency list representing the transposed edges.
    @usableFromInline var adjacencyList: [Node: [GraphEdge<Node, Edge>]] = [:]

    /// Initializes a new transposed graph with the given base graph.
    /// - Parameter base: The base graph from which the transpose is derived.
    @inlinable public init(base: Base) {
        self.base = base
        for edge in base.allEdges {
            adjacencyList[edge.destination, default: []].append(edge.reversed)
        }
    }

    /// Returns the edges originating from the specified node in the transposed graph.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges from the specified node in the transposed graph.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        return adjacencyList[node] ?? []
    }

    /// All nodes in the transposed graph.
    @inlinable public var allNodes: [Base.Node] {
        base.allNodes
    }

    /// All edges in the transposed graph.
    @inlinable public var allEdges: [GraphEdge<Base.Node, Base.Edge>] {
        base.allEdges.map(\.reversed)
    }

    /// Subscript that accesses members on the underlying graph instance
    @inlinable public subscript<Member>(dynamicMember keyPath: KeyPath<Base, Member>) -> Member {
        base[keyPath: keyPath]
    }
}
