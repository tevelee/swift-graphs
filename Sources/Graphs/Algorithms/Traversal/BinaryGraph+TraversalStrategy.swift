/// A protocol defining a strategy for traversing a binary graph.
public protocol BinaryGraphTraversalStrategy<Node, Edge, Visit> {
    /// The type of nodes in the graph.
    associatedtype Node
    /// The type of edges in the graph.
    associatedtype Edge
    /// The type of visits produced during traversal.
    associatedtype Visit
    /// The type of storage used by the strategy during traversal.
    associatedtype Storage

    /// Initializes the storage for the traversal starting from the specified node.
    /// - Parameter startNode: The node from which to start the traversal.
    /// - Returns: The initialized storage for the traversal.
    @inlinable func initializeStorage(startNode: Node) -> Storage

    /// Advances to the next visit in the traversal sequence.
    /// - Parameters:
    ///   - storage: The storage used by the strategy during traversal.
    ///   - graph: The graph being traversed.
    /// - Returns: The next visit in the traversal sequence, or `nil` if there are no more visits.
    @inlinable func next(from storage: inout Storage, graph: some BinaryGraph<Node, Edge>) -> Visit?
}
