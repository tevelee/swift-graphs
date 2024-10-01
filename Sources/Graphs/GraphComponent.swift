/// A protocol that defines the basic requirements for a graph structure.
public protocol GraphComponent<Node, Edge> {
    /// The type of nodes in the graph.
    associatedtype Node
    /// The type of edges in the graph. Defaults to `Empty`.
    associatedtype Edge = Empty

    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges from the specified node.
    @inlinable func edges(from node: Node) -> [GraphEdge<Node, Edge>]
}

/// A type that represents an empty value, but – unlike Void – allows to conform it to protocols.
public struct Empty: Equatable, Hashable {
    /// Creates an empty instance
    @inlinable public init() {}
}

/// A structure representing an edge in a graph.
public struct GraphEdge<Node, Value> {
    /// The source node of the edge.
    public let source: Node
    /// The destination node of the edge.
    public let destination: Node
    /// The value associated with the edge.
    public let value: Value

    /// Initializes a new graph edge with the given source, destination, and value.
    /// - Parameters:
    ///   - source: The source node of the edge.
    ///   - destination: The destination node of the edge.
    ///   - value: The value associated with the edge. Defaults to `()`.
    @inlinable public init(source: Node, destination: Node, value: Value = Empty()) {
        self.source = source
        self.destination = destination
        self.value = value
    }

    /// Returns a new edge with the source and destination nodes reversed.
    @inlinable public var reversed: Self {
        GraphEdge(source: destination, destination: source, value: value)
    }

    /// Transforms the source and destination nodes of the edge using the provided closure.
    @inlinable public func mapNode<NewNode>(_ transform: (Node) -> NewNode) -> GraphEdge<NewNode, Value> {
        .init(source: transform(source), destination: transform(destination), value: value)
    }

    /// Transforms the value of the edge using the provided closure.
    @inlinable public func mapEdge<NewValue>(_ transform: (Value) -> NewValue) -> GraphEdge<Node, NewValue> {
        .init(source: source, destination: destination, value: transform(value))
    }
}

extension GraphEdge: Equatable where Node: Equatable, Value: Equatable {}
extension GraphEdge: Hashable where Node: Hashable, Value: Hashable {}
extension GraphEdge: Comparable where Node: Equatable, Value: Equatable, Value: Weighted {
    /// Compares two graph edges based on their weights.
    /// - Parameters:
    ///   - lhs: The left-hand side edge.
    ///   - rhs: The right-hand side edge.
    /// - Returns: `true` if the weight of the left-hand side edge is less than the weight of the right-hand side edge, `false` otherwise.
    @inlinable public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value.weight < rhs.value.weight
    }
}

extension GraphEdge: Weighted where Value: Weighted {
    /// The weight of the edge.
    @inlinable public var weight: Value.Weight {
        value.weight
    }
}
