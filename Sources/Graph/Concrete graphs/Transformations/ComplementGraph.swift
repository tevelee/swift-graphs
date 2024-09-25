/// A graph structure that represents the complement of a given base graph.
@dynamicMemberLookup
public struct ComplementGraph<Base: WholeGraphProtocol>: GraphProtocol where Base.Node: Hashable {
    public typealias Node = Base.Node
    public typealias Edge = Base.Edge

    /// The base graph from which the complement is derived.
    @usableFromInline let base: Base
    /// The default value for edges in the complement graph.
    @usableFromInline let defaultEdgeValue: Edge

    /// Initializes a new complement graph with the given base graph and default edge value.
    /// - Parameters:
    ///   - base: The base graph from which the complement is derived.
    ///   - defaultEdgeValue: The default value for edges in the complement graph.
    @inlinable public init(base: Base, defaultEdgeValue: Edge) {
        self.base = base
        self.defaultEdgeValue = defaultEdgeValue
    }

    /// Returns the edges originating from the specified node in the complement graph.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges from the specified node in the complement graph.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        let existingDestinations = Set(base.edges(from: node).map(\.destination))
        let allNodes = base.allNodes.filter { $0 != node }
        let complementDestinations = allNodes.filter { !existingDestinations.contains($0) }
        return complementDestinations.map {
            GraphEdge(source: node, destination: $0, value: defaultEdgeValue)
        }
    }

    /// Subscript that accesses members on the underlying graph instance
    @inlinable public subscript<Member>(dynamicMember keyPath: KeyPath<Base, Member>) -> Member {
        base[keyPath: keyPath]
    }
}
