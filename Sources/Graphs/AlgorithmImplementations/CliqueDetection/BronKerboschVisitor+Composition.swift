#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
/// Extension providing composition support for Bron-Kerbosch clique detection algorithm visitors.
extension BronKerboschCliqueDetection.Visitor: Composable {
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: Self) -> Self {
        .init(
            exploreClique: { clique in
                self.exploreClique?(clique)
                other.exploreClique?(clique)
            },
            foundClique: { clique in
                self.foundClique?(clique)
                other.foundClique?(clique)
            },
            choosePivot: { pivot in
                self.choosePivot?(pivot)
                other.choosePivot?(pivot)
            },
            backtrack: { clique in
                self.backtrack?(clique)
                other.backtrack?(clique)
            }
        )
    }
}
#endif
