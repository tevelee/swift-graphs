extension VisitorProtocol {
    /// Returns a visitor that tracks the nodes visited during traversal.
    @inlinable public static func trackVisitedNodes<Node, Edge>() -> Self where Self == NodesTrackingVisitor<NodeVisitor<Node, Edge>, Node>, Node: Hashable {
        NodeVisitor().trackVisitedNodes()
    }

    /// Wraps the current visitor to track the nodes visited during traversal.
    @inlinable public func trackVisitedNodes() -> NodesTrackingVisitor<Self, Node> where Node: Hashable {
        NodesTrackingVisitor(base: self) { $0 }
    }

    /// Returns a visitor that tracks the nodes visited during traversal.
    /// - Parameter hashValue: A closure that computes the hash value of a node.
    /// - Returns: A visitor that tracks the nodes visited during traversal.
    @inlinable public static func trackVisitedNodes<Node, Edge, HashValue: Hashable>(by hashValue: @escaping (Node) -> HashValue) -> Self where Self == NodesTrackingVisitor<NodeVisitor<Node, Edge>, HashValue> {
        NodeVisitor().trackVisitedNodes(by: hashValue)
    }

    /// Wraps the current visitor to track the nodes visited during traversal.
    /// - Parameter hashValue: A closure that computes the hash value of a node.
    /// - Returns: A visitor that tracks the nodes visited during traversal.
    @inlinable public func trackVisitedNodes<HashValue: Hashable>(by hashValue: @escaping (Node) -> HashValue) -> NodesTrackingVisitor<Self, HashValue> {
        NodesTrackingVisitor(base: self, hashValue: hashValue)
    }
}

/// A visitor that tracks the nodes visited during traversal.
public struct NodesTrackingVisitor<Base: VisitorProtocol, HashValue: Hashable>: VisitorProtocol {
    public typealias Node = Base.Node
    public typealias Edge = Base.Edge

    /// A visit instance representing the current visit, including the depth of the node.
    public struct Visit: NodesTracking {
        /// The base visit instance.
        public let base: Base.Visit
        /// The node being visited.
        public let node: Node
        /// The set of visited nodes.
        public let visitedNodes: Set<HashValue>

        /// Creates a new visit instance.
        /// - Parameter base: The base visit instance.
        /// - Parameter node: The node being visited.
        /// - Parameter visitedNodes: The set of visited nodes.
        @inlinable public init(base: Base.Visit, node: Node, visitedNodes: Set<HashValue>) {
            self.base = base
            self.node = node
            self.visitedNodes = visitedNodes
        }
    }

    /// The base visitor used during traversal.
    public let base: Base
    /// A closure that computes the hash value of a node.
    public let hashValue: (Node) -> HashValue

    /// Creates a new visitor that tracks the nodes visited during traversal.
    /// - Parameter base: The base visitor used during traversal.
    /// - Parameter hashValue: A closure that computes the hash value of a node.
    @inlinable public init(base: Base, hashValue: @escaping (Node) -> HashValue) {
        self.base = base
        self.hashValue = hashValue
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
        var visitedNodes = previousVisit.map { $0.visit.visitedNodes } ?? []
        visitedNodes.insert(hashValue(node))
        return Visit(
            base: base.visit(node: node, from: previousVisit.map { ($0.visit.base, $0.edge) }),
            node: node,
            visitedNodes: visitedNodes
        )
    }
}

/// A visitor that tracks the nodes visited during traversal.
public protocol NodesTracking: DepthMeasuring {
    /// The hash value type used to track visited nodes.
    associatedtype HashValue: Hashable

    /// The set of visited nodes.
    var visitedNodes: Set<HashValue> { get }
}

extension NodesTracking {
    /// The depth of the current visit.
    public var depth: Int {
        visitedNodes.count
    }
}

extension NodesTrackingVisitor.Visit: Equatable where Base.Node: Equatable, Base.Visit: Equatable {}
extension NodesTrackingVisitor.Visit: Hashable where Base.Node: Hashable, Base.Visit: Hashable {}
