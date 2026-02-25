#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
extension ClosenessCentrality.Visitor: Composable {
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
            computeDistance: { source, destination, distance in
                self.computeDistance?(source, destination, distance)
                other.computeDistance?(source, destination, distance)
            }
        )
    }
}
#endif
