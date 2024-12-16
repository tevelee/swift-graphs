extension VisitorProtocol {
    /// Creates a visitor that tracks the ancestor of each node during traversal.
    /// - Returns: An instance of `AncestorVisitor` configured to track the ancestor of each node.
    @inlinable public static func trackAncestor<Node, Edge>() -> Self where Self == AncestorTrackingVisitor<NodeVisitor<Node, Edge>> {
        NodeVisitor().trackAncestor()
    }

    /// Wraps the current visitor to track the ancestor of each node during traversal.
    /// - Returns: An instance of `AncestorVisitor` that wraps the current visitor.
    @inlinable public func trackAncestor() -> AncestorTrackingVisitor<Self> {
        AncestorTrackingVisitor(base: self)
    }
}

/// A visitor that tracks the ancestor of each node during traversal.
public struct AncestorTrackingVisitor<Base: VisitorProtocol>: VisitorProtocol {
    public typealias Node = Base.Node
    public typealias Edge = Base.Edge

    /// A visit instance that includes the ancestor of the node.
    public struct Visit {
        /// The base visit instance.
        public let base: Base.Visit
        /// The node being visited.
        public let node: Node
        /// The ancestor of the node.
        public let ancestor: Node?

        /// Initializes a new Visit containing the base visit and ancestor.
        /// - Parameters:
        ///  - base: The base visit instance.
        ///  - node: The node being visited.
        ///  - ancestor: The ancestor of the node.
        @inlinable public init(base: Base.Visit, node: Node, ancestor: Node?) {
            self.base = base
            self.node = node
            self.ancestor = ancestor
        }
    }

    /// The base visitor used during traversal.
    public let base: Base

    /// Initializes a new `AncestorVisitor` with the given base visitor.
    /// - Parameter base: The base visitor to wrap.
    @inlinable public init(base: Base) {
        self.base = base
    }

    /// Extracts the node from a visit.
    /// - Parameter visit: The visit from which to extract the node.
    /// - Returns: The node associated with the visit.
    @inlinable public func node(from visit: Visit) -> Node {
        base.node(from: visit.base)
    }

    /// Visits a node during traversal, tracking the ancestor of the node.
    /// - Parameters:
    ///   - node: The node being visited.
    ///   - previousVisit: An optional tuple containing the previous visit and the edge leading to the current node.
    /// - Returns: A visit instance representing the current visit, including the ancestor of the node.
    @inlinable public func visit(node: Node, from previousVisit: (visit: Visit, edge: GraphEdge<Node, Edge>)?) -> Visit {
        Visit(
            base: base.visit(node: node, from: previousVisit.map { ($0.visit.base, $0.edge) }),
            node: node,
            ancestor: previousVisit.map(\.visit.node)
        )
    }
}

extension AncestorTrackingVisitor.Visit: Equatable where Base.Node: Equatable, Base.Visit: Equatable {}
extension AncestorTrackingVisitor.Visit: Hashable where Base.Node: Hashable, Base.Visit: Hashable {}
