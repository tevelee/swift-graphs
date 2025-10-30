extension EigenvectorCentrality.Visitor: Composable {
    public typealias Other = Self
    
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: Self) -> Self {
        Self(
            startIteration: { iteration in
                self.startIteration?(iteration)
                other.startIteration?(iteration)
            },
            endIteration: { iteration, values in
                self.endIteration?(iteration, values)
                other.endIteration?(iteration, values)
            },
            converge: { iteration, values in
                self.converge?(iteration, values)
                other.converge?(iteration, values)
            }
        )
    }
}

