extension GraphTraversalStrategy {
    /// Creates a traversal strategy that visits each node once.
    /// - Returns: A `UniqueTraversalStrategy` instance configured to visit each node once.
    @inlinable public func visitEachNodeOnce() -> UniqueTraversalStrategy<Self, some Hashable> where Node: Hashable {
        visitEachNodeOnce { $0 }
    }

    /// Creates a traversal strategy that visits each node once, using a custom hash value.
    /// - Parameter hashValue: A closure that takes a node and returns its hash value.
    /// - Returns: A `UniqueTraversalStrategy` instance configured to visit each node once using the custom hash value.
    @inlinable public func visitEachNodeOnce<HashValue>(by hashValue: @escaping (Node) -> HashValue) -> UniqueTraversalStrategy<Self, HashValue> {
        .init(base: self, hashValue: hashValue)
    }
}

/// A traversal strategy that ensures each node is visited only once.
public struct UniqueTraversalStrategy<Base: GraphTraversalStrategy, HashValue: Hashable>: GraphTraversalStrategy {
    public typealias Node = Base.Node
    public typealias Edge = Base.Edge
    public typealias Visit = Base.Visit
    public typealias Storage = (base: Base.Storage, visited: Set<HashValue>)

    /// The base traversal strategy.
    public var base: Base
    /// A closure to compute the hash value of a node.
    public var hashValue: (Node) -> HashValue

    /// Initializes a new unique traversal strategy with the given base strategy and hash value function.
    /// - Parameters:
    ///   - base: The base traversal strategy.
    ///   - hashValue: A closure that takes a node and returns its hash value.
    @inlinable public init(base: Base, hashValue: @escaping (Node) -> HashValue) {
        self.base = base
        self.hashValue = hashValue
    }

    /// Initializes the storage for the traversal starting from the specified node.
    /// - Parameter startNode: The node from which to start the traversal.
    /// - Returns: The initialized storage for the traversal.
    @inlinable public func initializeStorage(startNode: Node) -> Storage {
        (base: base.initializeStorage(startNode: startNode), visited: [])
    }

    /// Advances to the next visit in the traversal sequence.
    /// - Parameters:
    ///   - storage: The storage used by the strategy during traversal.
    ///   - edges: A closure that returns the edges for a given node.
    /// - Returns: The next visit in the traversal sequence, or `nil` if there are no more visits.
    @inlinable public func next(from storage: inout Storage, edges: (Node) -> some Sequence<GraphEdge<Node, Edge>>) -> Visit? {
        while let visit = base.next(from: &storage.base, edges: {
            edges($0).filter {
                !storage.visited.contains(hashValue($0.destination))
            }
        }) {
            let node = base.node(from: visit)
            if storage.visited.contains(hashValue(node)) {
                continue
            }
            defer {
                storage.visited.insert(hashValue(node))
            }
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
