import Collections

extension GraphTraversalStrategy {
    /// Creates a breadth-first search traversal strategy with the specified visitor.
    /// - Parameter visitor: The visitor to use during traversal.
    /// - Returns: A `BreadthFirstSearch` instance configured with the specified visitor.
    @inlinable public static func bfs<Visitor: VisitorProtocol>(
        _ visitor: Visitor
    ) -> Self where Self == BreadthFirstSearch<Visitor> {
        .init(visitor: visitor)
    }

    /// Creates a breadth-first search traversal strategy with a default node visitor.
    /// - Returns: A `BreadthFirstSearch` instance configured with a default node visitor.
    @inlinable public static func bfs<Node, Edge>() -> Self where Self == BreadthFirstSearch<NodeVisitor<Node, Edge>> {
        .init(visitor: .onlyNodes())
    }
}

/// A breadth-first search traversal strategy.
public struct BreadthFirstSearch<Visitor: VisitorProtocol>: GraphTraversalStrategy {
    public typealias Storage = Deque<Visitor.Visit>
    public typealias Node = Visitor.Node
    public typealias Edge = Visitor.Edge
    public typealias Visit = Visitor.Visit

    /// The visitor used during traversal.
    public let visitor: Visitor

    /// Initializes a new breadth-first search traversal strategy with the specified visitor.
    /// - Parameter visitor: The visitor to use during traversal.
    @inlinable public init(visitor: Visitor) {
        self.visitor = visitor
    }

    /// Initializes the storage for the traversal starting from the specified node.
    /// - Parameter startNode: The node from which to start the traversal.
    /// - Returns: The initialized storage for the traversal.
    @inlinable public func initializeStorage(startNode: Node) -> Storage {
        Deque([visitor.visit(node: startNode, from: nil)])
    }

    /// Advances to the next visit in the traversal sequence.
    /// - Parameters:
    ///   - queue: The storage used by the strategy during traversal.
    ///   - edges: A closure that returns the edges for a given node.
    /// - Returns: The next visit in the traversal sequence, or `nil` if there are no more visits.
    @inlinable public func next(from queue: inout Storage, edges: (Node) -> some Sequence<GraphEdge<Node, Edge>>) -> Visit? {
        guard let visit = queue.popFirst() else { return nil }
        let visits = edges(node(from: visit)).map { edge in
            visitor.visit(node: edge.destination, from: (visit, edge))
        }
        queue.append(contentsOf: visits)
        return visit
    }

    /// Extracts the node from a visit.
    /// - Parameter visit: The visit from which to extract the node.
    /// - Returns: The node associated with the visit.
    @inlinable public func node(from visit: Visit) -> Node {
        visitor.node(from: visit)
    }
}
