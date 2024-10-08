extension GraphTraversalStrategy where Visit: DepthMeasuring {
    /// Limits the traversal to a maximum depth.
    /// - Parameter maxDepth: The maximum depth to traverse.
    /// - Returns: A depth-limited traversal strategy.
    @inlinable public func limited(maxDepth: Int) -> DepthLimitedTraversalStrategy<Self> {
        .init(base: self, maxDepth: maxDepth)
    }
}

/// A graph traversal strategy that limits traversal to a maximum depth.
public struct DepthLimitedTraversalStrategy<Base: GraphTraversalStrategy>: GraphTraversalStrategy where Base.Visit: DepthMeasuring {
    public typealias Node = Base.Node
    public typealias Edge = Base.Edge
    public typealias Visit = Base.Visit
    public typealias Storage = Base.Storage

    /// The base traversal strategy.
    public var base: Base
    /// The maximum depth to traverse.
    public var maxDepth: Int

    /// Initializes a new depth-limited traversal strategy.
    /// - Parameters:
    ///  - base: The base traversal strategy.
    ///  - maxDepth: The maximum depth to traverse.
    @inlinable public init(base: Base, maxDepth: Int) {
        self.base = base
        self.maxDepth = maxDepth
    }

    /// Initializes the storage for the traversal.
    /// - Parameter startNode: The node from which to start the traversal.
    /// - Returns: The storage containing the nodes to visit.
    @inlinable public func initializeStorage(startNode: Node) -> Storage {
        base.initializeStorage(startNode: startNode)
    }

    /// Retrieves the next node to visit from the storage.
    /// - Parameters:
    ///  - storage: The storage containing the nodes to visit.
    ///  - edges: A closure that returns the edges leading from a node.
    /// - Returns: The next node to visit, or `nil` if the traversal is complete.
    @inlinable public func next(from storage: inout Storage, edges: (Node) -> some Sequence<GraphEdge<Node, Edge>>) -> Visit? {
        while let visit = base.next(from: &storage, edges: edges) {
            if visit.depth <= maxDepth {
                return visit
            }
        }
        return nil
    }

    /// Visits a node during traversal.
    /// - Parameter visit: The visit instance representing the current node.
    /// - Returns: The visit instance representing the current node.
    @inlinable public func node(from visit: Visit) -> Node {
        base.node(from: visit)
    }
}
