#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
extension DegreeCentrality.Visitor: Composable {
    public typealias Other = Self
    
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: Self) -> Self {
        Self(
            examineVertex: { vertex in
                self.examineVertex?(vertex)
                other.examineVertex?(vertex)
            },
            computeDegree: { vertex, degree in
                self.computeDegree?(vertex, degree)
                other.computeDegree?(vertex, degree)
            }
        )
    }
}
#endif
