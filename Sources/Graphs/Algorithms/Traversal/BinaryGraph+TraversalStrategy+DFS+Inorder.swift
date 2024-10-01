import Collections

extension DepthFirstSearch {
    /// Creates an inorder depth-first search order.
    /// - Returns: An instance of `DFSOrder` configured for inorder traversal.
    @inlinable public static func inorder<Visitor: VisitorProtocol>() -> Self where Self == DepthFirstSearch<DepthFirstSearchInorder<Visitor>> {
        .init()
    }
}

extension BinaryGraphTraversalStrategy {
    /// Creates a depth-first search strategy with the specified visitor and order.
    /// - Parameters:
    ///   - visitor: The visitor to use during traversal.
    ///   - order: The order in which to perform the depth-first search.
    /// - Returns: An instance of `DepthFirstSearchInorder` configured with the specified visitor and order.
    @inlinable public static func dfs<Visitor: VisitorProtocol>(
        _ visitor: Visitor,
        order: DepthFirstSearch<DepthFirstSearchInorder<Visitor>>
    ) -> Self where Self == DepthFirstSearchInorder<Visitor> {
        .init(visitor: visitor)
    }

    /// Creates a depth-first search strategy with the specified order.
    /// - Parameter order: The order in which to perform the depth-first search.
    /// - Returns: An instance of `DepthFirstSearchInorder` configured with the specified order.
    @inlinable public static func dfs<Node, Edge>(
        order: DepthFirstSearch<DepthFirstSearchInorder<NodeVisitor<Node, Edge>>>
    ) -> Self where Self == DepthFirstSearchInorder<NodeVisitor<Node, Edge>> {
        .init(visitor: .onlyNodes())
    }
}

/// A depth-first search strategy that performs an inorder traversal.
public struct DepthFirstSearchInorder<Visitor: VisitorProtocol>: BinaryGraphTraversalStrategy {
    public typealias Node = Visitor.Node
    public typealias Edge = Visitor.Edge
    public typealias Visit = Visitor.Visit
    public typealias Storage = Deque<(isFirst: Bool, visit: Visit)>

    /// The visitor used during traversal.
    public let visitor: Visitor

    /// Initializes a new inorder depth-first search strategy with the specified visitor.
    /// - Parameter visitor: The visitor to use during traversal.
    @inlinable public init(visitor: Visitor) {
        self.visitor = visitor
    }

    /// Initializes the storage for the traversal starting from the specified node.
    /// - Parameter startNode: The node from which to start the traversal.
    /// - Returns: The initialized storage for the traversal.
    @inlinable public func initializeStorage(startNode: Node) -> Storage {
        Deque([(isFirst: true, visit: visitor.visit(node: startNode, from: nil))])
    }

    /// Advances to the next visit in the traversal sequence.
    /// - Parameters:
    ///   - stack: The storage used by the strategy during traversal.
    ///   - graph: The graph being traversed.
    /// - Returns: The next visit in the traversal sequence, or `nil` if there are no more visits.
    @inlinable public func next(from stack: inout Storage, graph: some BinaryGraphComponent<Node, Edge>) -> Visitor.Visit? {
        guard let (isFirst, visit) = stack.popLast() else { return nil }
        if isFirst {
            let edges = graph.edges(from: node(from: visit))
            if let edge = edges.rhs {
                stack.append((isFirst: true, visit: visitor.visit(node: edge.destination, from: (visit, edge))))
            }
            stack.append((isFirst: false, visit: visit))
            if let edge = edges.lhs {
                stack.append((isFirst: true, visit: visitor.visit(node: edge.destination, from: (visit, edge))))
            }
            return next(from: &stack, graph: graph)
        } else {
            return visit
        }
    }

    /// Extracts the node from a visit.
    /// - Parameter visit: The visit from which to extract the node.
    /// - Returns: The node associated with the visit.
    @inlinable public func node(from visit: Visit) -> Node {
        visitor.node(from: visit)
    }
}
