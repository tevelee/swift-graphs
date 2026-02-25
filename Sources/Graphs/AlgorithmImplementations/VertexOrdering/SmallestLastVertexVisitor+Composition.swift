#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
/// Extension providing composition support for smallest last vertex ordering algorithm visitors.
extension SmallestLastVertexOrderingAlgorithm.Visitor: Composable {
    public typealias Other = Self
    
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: Self) -> Self {
        Self(
            examineVertex: other.examineVertex ?? self.examineVertex,
            removeVertex: other.removeVertex ?? self.removeVertex,
            updateDegree: other.updateDegree ?? self.updateDegree
        )
    }
}
#endif
