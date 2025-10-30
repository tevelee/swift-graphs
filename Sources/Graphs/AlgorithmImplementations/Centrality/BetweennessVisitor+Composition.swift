extension BetweennessCentrality.Visitor: Composable {
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
            foundShortestPath: { source, destination, distance in
                self.foundShortestPath?(source, destination, distance)
                other.foundShortestPath?(source, destination, distance)
            }
        )
    }
}

