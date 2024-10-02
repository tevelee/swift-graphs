import Collections

extension DepthFirstSearch {
    /// Creates a preorder depth-first search order.
    /// - Returns: An instance of `DFSOrder` configured for preorder traversal.
    @inlinable public static func preorder<Visitor: VisitorProtocol>() -> Self
    where Self == DepthFirstSearch<DepthFirstSearchPreorder<Visitor>> {
        .init()
    }
}

extension GraphTraversalStrategy {
    /// Creates a depth-first search strategy with the specified visitor and order.
    /// - Parameters:
    ///   - visitor: The visitor to use during traversal.
    ///   - order: The order in which to perform the depth-first search.
    /// - Returns: An instance of `DepthFirstSearchPreorder` configured with the specified visitor and order.
    @inlinable public static func dfs<Visitor: VisitorProtocol>(
        _ visitor: Visitor,
        order: DepthFirstSearch<DepthFirstSearchPreorder<Visitor>>
    ) -> Self where Self == DepthFirstSearchPreorder<Visitor> {
        .init(visitor: visitor)
    }

    /// Creates a depth-first search strategy with the specified order.
    /// - Parameter order: The order in which to perform the depth-first search.
    /// - Returns: An instance of `DepthFirstSearchPreorder` configured with the specified order.
    @inlinable public static func dfs<Node, Edge>(
        order: DepthFirstSearch<DepthFirstSearchPreorder<NodeVisitor<Node, Edge>>>
    ) -> Self where Self == DepthFirstSearchPreorder<NodeVisitor<Node, Edge>> {
        .init(visitor: .onlyNodes())
    }
}

/// A depth-first search strategy that performs a preorder traversal.
public struct DepthFirstSearchPreorder<Visitor: VisitorProtocol>: GraphTraversalStrategy {
    public typealias Storage = Deque<Visitor.Visit>
    public typealias Node = Visitor.Node
    public typealias Edge = Visitor.Edge
    public typealias Visit = Visitor.Visit

    /// The visitor used during traversal.
    public let visitor: Visitor

    /// Initializes a new preorder depth-first search strategy with the specified visitor.
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
    ///   - stack: The storage used by the strategy during traversal.
    ///   - edges: A closure that returns the edges for a given node.
    /// - Returns: The next visit in the traversal sequence, or `nil` if there are no more visits.
    @inlinable public func next(from stack: inout Storage, edges: (Node) -> some Sequence<GraphEdge<Node, Edge>>) -> Visit? {
        guard let visit = stack.popLast() else { return nil }
        let visits = edges(node(from: visit)).reversed().map { edge in
            visitor.visit(node: edge.destination, from: (visit, edge))
        }
        stack.append(contentsOf: visits)
        return visit
    }

    /// Extracts the node from a visit.
    /// - Parameter visit: The visit from which to extract the node.
    /// - Returns: The node associated with the visit.
    @inlinable public func node(from visit: Visit) -> Node {
        visitor.node(from: visit)
    }
}
