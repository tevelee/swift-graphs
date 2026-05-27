/// A vertex property storing the shortest-path distance from a source as ``Cost``.
///
/// Used by weighted shortest-path algorithms (Dijkstra, Uniform-Cost Search, A*, etc.) to record
/// the best-known distance to each vertex. The default value is ``Cost/infinite``, meaning the
/// vertex has not been relaxed yet.
public enum DistanceProperty<Weight>: VertexProperty, Sendable {
    /// The default distance: ``Cost/infinite``.
    @inlinable
    public static var defaultValue: Cost<Weight> { .infinite }
}

/// A vertex property storing the predecessor edge on a shortest path or traversal tree.
///
/// Used by shortest-path and traversal algorithms (Dijkstra, A*, BFS, DFS, etc.) to record the
/// edge by which each vertex was first reached. The default value is `nil`, meaning the vertex
/// either has no predecessor (the source) or has not been discovered yet.
public enum PredecessorEdgeProperty<Edge>: VertexProperty, Sendable {
    /// The default predecessor edge: `nil`.
    @inlinable
    public static var defaultValue: Edge? { nil }
}
