#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
/// Extension providing composition support for Yen's algorithm visitors.
extension Yen.Visitor: Composable {
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: Self) -> Self {
        .init(
            onPathFound: { path in
                self.onPathFound(path)
                other.onPathFound(path)
            },
            onCandidateAdded: { path, cost in
                self.onCandidateAdded(path, cost)
                other.onCandidateAdded(path, cost)
            },
            onPathSelected: { path, cost in
                self.onPathSelected(path, cost)
                other.onPathSelected(path, cost)
            }
        )
    }
}
#endif
