extension VisitorProtocol {
    /// Creates a visitor that tracks the path of each node during traversal.
    /// - Returns: An instance of `PathVisitor` configured to track the path of each node.
    @inlinable public static func trackPath<Node, Edge>() -> Self where Self == PathTrackingVisitor<NodeVisitor<Node, Edge>> {
        NodeVisitor().trackPath()
    }

    /// Wraps the current visitor to track the path of each node during traversal.
    /// - Returns: An instance of `PathVisitor` that wraps the current visitor.
    @inlinable public func trackPath() -> PathTrackingVisitor<Self> {
        PathTrackingVisitor(base: self)
    }
}

/// A visitor that tracks the path of each node during traversal.
public struct PathTrackingVisitor<Base: VisitorProtocol>: VisitorProtocol {
    public typealias Node = Base.Node
    public typealias Edge = Base.Edge

    /// A structure representing a visit during traversal, including the path of edges.
    public struct Visit {
        /// The base visit.
        public let base: Base.Visit
        /// The node being visited.
        public let node: Base.Node
        /// The edges leading to the node.
        public let edges: [GraphEdge<Node, Edge>]

        /// Initializes a new `Visit` instance with the given base visit, node, and edges.
        /// - Parameters:
        ///   - base: The base visit.
        ///   - node: The node being visited.
        ///   - edges: The edges leading to the node.
        @inlinable public init(base: Base.Visit, node: Node, edges: [GraphEdge<Node, Edge>]) {
            self.base = base
            self.node = node
            self.edges = edges
        }

        /// The path of nodes from the start node to the current node.
        @inlinable public var path: [Node] {
            edges.map(\.source) + [node]
        }
    }

    /// The base visitor used during traversal.
    public let base: Base

    /// Initializes a new `PathTrackingVisitor` with the given base visitor.
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

    /// Visits a node during traversal, tracking the path of the connecting edges.
    /// - Parameters:
    ///   - node: The node being visited.
    ///   - previousVisit: An optional tuple containing the previous visit and the edge leading to the current node.
    /// - Returns: A visit instance representing the current visit, including the path of the connecting edges.
    @inlinable public func visit(node: Node, from previousVisit: (visit: Visit, edge: GraphEdge<Node, Edge>)?) -> Visit {
        Visit(
            base: base.visit(node: node, from: previousVisit.map { ($0.visit.base, $0.edge) }),
            node: node,
            edges: previousVisit.map { $0.visit.edges + [$0.edge] } ?? []
        )
    }
}

extension PathTrackingVisitor.Visit where Base.Edge: Weighted, Base.Edge.Weight: Numeric {
    /// The cost, representing the sum of the weights along the path of edges
    @inlinable public var cost: Base.Edge.Weight {
        edges.lazy.map(\.value.weight).reduce(into: .zero, +=)
    }
}
