extension GraphTraversalStrategy {
    /// Returns a traversal strategy that ensures acyclic traversal.
    @inlinable public func acyclic() -> AcyclicTraversalStrategy<Self, Node> where Node: Hashable {
        acyclic { $0 }
    }

    /// Returns a traversal strategy that ensures acyclic traversal.
    /// - Parameter hashValue: A closure to compute the hash value of a node.
    /// - Returns: A traversal strategy that ensures acyclic traversal.
    @inlinable public func acyclic<HashValue: Hashable>(
        by hashValue: @escaping (Node) -> HashValue
    ) -> AcyclicTraversalStrategy<
        Self, HashValue
    > {
        .init(base: self, hashValue: hashValue)
    }
}

/// A traversal strategy that ensures acyclic traversal.
public struct AcyclicTraversalStrategy<Base: GraphTraversalStrategy, HashValue: Hashable>: GraphTraversalStrategy where Base.Visit: NodesTracking, Base.Visit.HashValue == HashValue {
    public typealias Node = Base.Node
    public typealias Edge = Base.Edge
    public typealias Visit = Base.Visit
    public typealias Storage = Base.Storage

    /// The base traversal strategy.
    public var base: Base
    /// A closure to compute the hash value of a node.
    public var hashValue: (Node) -> HashValue

    /// Creates a new traversal strategy that ensures acyclic traversal.
    /// - Parameter base: The base traversal strategy.
    /// - Parameter hashValue: A closure to compute the hash value of a node.
    @inlinable public init(base: Base, hashValue: @escaping (Node) -> HashValue) {
        self.base = base
        self.hashValue = hashValue
    }

    /// Initializes the storage for the traversal starting from the specified node.
    /// - Parameter startNode: The node from which to start the traversal.
    /// - Returns: The initialized storage for the traversal.
    @inlinable public func initializeStorage(startNode: Node) -> Storage {
        base.initializeStorage(startNode: startNode)
    }

    /// Advances to the next visit in the traversal sequence.
    /// - Parameters:
    ///   - storage: The storage used by the strategy during traversal.
    ///   - edges: A closure that returns the edges for a given node.
    /// - Returns: The next visit in the traversal sequence, or `nil` if there are no more visits.
    @inlinable public func next(from storage: inout Storage, edges: (Node) -> some Sequence<GraphEdge<Node, Edge>>) -> Visit? {
        while let visit = base.next(
            from: &storage,
            edges: edges
        ), !visit.visitedNodes.contains(hashValue(node(from: visit))) {
            return visit
        }
        return nil
    }

    /// Extracts the node from a visit.
    /// - Parameter visit: The visit from which to extract the node.
    /// - Returns: The node associated with the visit.
    @inlinable public func node(from visit: Visit) -> Node {
        base.node(from: visit)
    }
}
