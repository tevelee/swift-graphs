import Collections

/// A structure representing the order of a depth-first search traversal.
public struct DFSOrder<Concrete> {
    /// Initializes a new `DFSOrder` instance.
    @inlinable public init() {}
}

extension GraphTraversalStrategy {
    /// Creates a depth-first search traversal strategy with the specified visitor.
    /// - Parameter visitor: The visitor to use during traversal.
    /// - Returns: A `DepthFirstSearchPreorder` instance configured with the specified visitor.
    @inlinable public static func dfs<Visitor: VisitorProtocol>(
        _ visitor: Visitor
    ) -> Self where Self == DepthFirstSearchPreorder<Visitor> {
        .init(visitor: visitor)
    }

    /// Creates a depth-first search traversal strategy with a default node visitor.
    /// - Returns: A `DepthFirstSearchPreorder` instance configured with a default node visitor.
    @inlinable public static func dfs<Node, Edge>() -> Self where Self == DepthFirstSearchPreorder<NodeVisitor<Node, Edge>> {
        .init(visitor: .onlyNodes())
    }
}
