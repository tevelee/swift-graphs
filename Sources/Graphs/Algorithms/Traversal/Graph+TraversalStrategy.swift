/// A protocol that defines the requirements for a graph traversal strategy.
public protocol GraphTraversalStrategy<Node, Edge, Visit> {
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
    ///   - edges: A closure that returns the edges for a given node.
    /// - Returns: The next visit in the traversal sequence, or `nil` if there are no more visits.
    @inlinable func next(from storage: inout Storage, edges: (Node) -> some Sequence<GraphEdge<Node, Edge>>) -> Visit?

    /// Extracts the node from a visit.
    /// - Parameter visit: The visit from which to extract the node.
    /// - Returns: The node associated with the visit.
    @inlinable func node(from visit: Visit) -> Node
}

extension GraphTraversalStrategy {
    /// Advances to the next visit in the traversal sequence using a graph.
    /// - Parameters:
    ///   - storage: The storage used by the strategy during traversal.
    ///   - graph: The graph being traversed.
    /// - Returns: The next visit in the traversal sequence, or `nil` if there are no more visits.
    @inlinable public func next(from storage: inout Storage, graph: some GraphComponent<Node, Edge>) -> Visit? {
        next(from: &storage, edges: graph.edges)
    }
}
