#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
/// Extension providing composition support for reverse Cuthill-McKee ordering algorithm visitors.
extension ReverseCuthillMcKeeOrderingAlgorithm.Visitor: Composable {
    public typealias Other = Self
    
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: Self) -> Self {
        Self(
            examineVertex: other.examineVertex ?? self.examineVertex,
            enqueueVertex: other.enqueueVertex ?? self.enqueueVertex,
            dequeueVertex: other.dequeueVertex ?? self.dequeueVertex,
            startFromVertex: other.startFromVertex ?? self.startFromVertex
        )
    }
}
#endif
