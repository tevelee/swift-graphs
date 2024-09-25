/// A protocol that defines the requirements for a binary graph structure.
public protocol BinaryGraphProtocol<Node, Edge>: GraphProtocol {
    /// The type of nodes in the graph.
    associatedtype Node
    /// The type of edges in the graph. Defaults to `Void`.
    associatedtype Edge = Void

    /// Returns the binary edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: A `BinaryGraphEdges` instance containing the edges from the specified node.
    @inlinable func edges(from node: Node) -> BinaryGraphEdges<Node, Edge>
}

/// A structure representing the edges of a node in a binary graph.
public struct BinaryGraphEdges<Node, Edge>: Container {
    /// The type of elements contained in the container.
    public typealias Element = GraphEdge<Node, Edge>

    /// The source node of the edges.
    public var source: Node
    /// The left-hand side edge.
    public var lhs: Element?
    /// The right-hand side edge.
    public var rhs: Element?

    /// Initializes a new `BinaryGraphEdges` instance with the given source node and edges.
    /// - Parameters:
    ///   - source: The source node of the edges.
    ///   - lhs: The left-hand side edge.
    ///   - rhs: The right-hand side edge.
    @inlinable public init(source: Node, lhs: Element?, rhs: Element?) {
        self.source = source
        self.lhs = lhs
        self.rhs = rhs
    }

    /// An array of elements contained in the container.
    @inlinable public var elements: [Element] { [lhs, rhs].compactMap(\.self) }
}

extension GraphProtocol where Self: BinaryGraphProtocol {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        let edges: BinaryGraphEdges<Node, Edge> = self.edges(from: node)
        return edges.elements
    }
}
