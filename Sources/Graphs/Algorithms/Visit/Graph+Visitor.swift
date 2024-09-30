/// A protocol that defines the requirements for a visitor in a graph traversal.
public protocol VisitorProtocol<Node, Edge> {
    /// The type of nodes in the graph.
    associatedtype Node
    /// The type of edges in the graph.
    associatedtype Edge
    /// The type of visits produced during traversal.
    associatedtype Visit

    /// Visits a node during traversal.
    /// - Parameters:
    ///   - node: The node being visited.
    ///   - previousVisit: An optional tuple containing the previous visit and the edge leading to the current node.
    /// - Returns: A visit instance representing the current visit.
    @inlinable func visit(node: Node, from previousVisit: (visit: Visit, edge: GraphEdge<Node, Edge>)?) -> Visit

    /// Extracts the node from a visit.
    /// - Parameter visit: The visit from which to extract the node.
    /// - Returns: The node associated with the visit.
    @inlinable func node(from visit: Visit) -> Node
}

extension VisitorProtocol {
    /// Creates a visitor that only visits nodes.
    /// - Returns: An instance of `NodeVisitor` configured to only visit nodes.
    @inlinable public static func onlyNodes<Node, Edge>() -> Self where Self == NodeVisitor<Node, Edge> {
        NodeVisitor()
    }
}

/// A visitor that only visits nodes in a graph traversal.
public struct NodeVisitor<Node, Edge>: VisitorProtocol {
    public typealias Visit = Node
    public typealias Storage = Void

    /// Initializes a new `NodeVisitor` instance.
    @inlinable public init() {}

    /// Visits a node during traversal.
    /// - Parameters:
    ///   - node: The node being visited.
    ///   - previousVisit: An optional tuple containing the previous visit and the edge leading to the current node.
    /// - Returns: The node being visited.
    @inlinable public func visit(node: Node, from: (visit: Visit, edge: GraphEdge<Node, Edge>)?) -> Visit {
        node
    }

    /// Extracts the node from a visit.
    /// - Parameter visit: The visit from which to extract the node.
    /// - Returns: The node associated with the visit.
    @inlinable public func node(from visit: Visit) -> Node {
        visit
    }
}
