extension VisitorProtocol {
    /// Creates a visitor that tracks the depth of each node during traversal.
    /// - Returns: An instance of `DepthVisitor` configured to track the depth of each node.
    @inlinable public static func trackDepth<Node, Edge>() -> Self where Self == DepthTrackingVisitor<NodeVisitor<Node, Edge>> {
        NodeVisitor().trackDepth()
    }

    /// Wraps the current visitor to track the depth of each node during traversal.
    /// - Returns: An instance of `DepthVisitor` that wraps the current visitor.
    @inlinable public func trackDepth() -> DepthTrackingVisitor<Self> {
        DepthTrackingVisitor(base: self)
    }
}

/// A visitor that tracks the depth of each node during traversal.
public struct DepthTrackingVisitor<Base: VisitorProtocol>: VisitorProtocol {
    public typealias Node = Base.Node
    public typealias Edge = Base.Edge

    /// A visit instance that includes the depth of the node.
    public struct Visit: DepthMeasuring {
        /// The base visit instance.
        public let base: Base.Visit
        /// The node being visited.
        public let node: Node
        /// The depth of the node.
        public let depth: Int

        /// Initializes a new Visit containing the base visit and depth.
        /// - Parameters:
        ///  - base: The base visit instance.
        ///  - node: The node being visited.
        ///  - depth: The depth of the node.
        @inlinable public init(base: Base.Visit, node: Node, depth: Int) {
            self.base = base
            self.node = node
            self.depth = depth
        }
    }

    /// The base visitor used during traversal.
    public let base: Base

    /// Initializes a new `DepthVisitor` with the given base visitor.
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

    /// Visits a node during traversal, tracking the depth of the node.
    /// - Parameters:
    ///   - node: The node being visited.
    ///   - previousVisit: An optional tuple containing the previous visit and the edge leading to the current node.
    /// - Returns: A visit instance representing the current visit, including the depth of the node.
    @inlinable public func visit(node: Node, from previousVisit: (visit: Visit, edge: GraphEdge<Node, Edge>)?) -> Visit {
        Visit(
            base: base.visit(node: node, from: previousVisit.map { ($0.visit.base, $0.edge) }),
            node: node,
            depth: previousVisit.map { $0.visit.depth + 1 } ?? 0
        )
    }
}

/// A protocol that represents a type that can measure the depth of a node.
public protocol DepthMeasuring {
    /// The depth of the node.
    var depth: Int { get }
}

extension DepthTrackingVisitor.Visit: Equatable where Base.Node: Equatable, Base.Visit: Equatable {}
extension DepthTrackingVisitor.Visit: Hashable where Base.Node: Hashable, Base.Visit: Hashable {}
