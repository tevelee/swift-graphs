#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
/// Extension providing composition support for Stoer-Wagner algorithm visitors.
extension StoerWagner.Visitor: Composable {
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: Self) -> Self {
        .init(
            startPhase: { phase in
                self.startPhase?(phase)
                other.startPhase?(phase)
            },
            addVertex: { vertex, weight in
                self.addVertex?(vertex, weight)
                other.addVertex?(vertex, weight)
            },
            phaseComplete: { phase, weight in
                self.phaseComplete?(phase, weight)
                other.phaseComplete?(phase, weight)
            },
            mergeVertices: { vertex1, vertex2 in
                self.mergeVertices?(vertex1, vertex2)
                other.mergeVertices?(vertex1, vertex2)
            },
            newMinimumCut: { weight in
                self.newMinimumCut?(weight)
                other.newMinimumCut?(weight)
            }
        )
    }
}
#endif
