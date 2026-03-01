#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
/// Extension providing composition support for Hopcroft-Karp algorithm visitors.
extension HopcroftKarp.Visitor: Composable {
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: Self) -> Self {
        .init(
            examineVertex: { vertex in
                self.examineVertex?(vertex)
                other.examineVertex?(vertex)
            },
            examineEdge: { edge in
                self.examineEdge?(edge)
                other.examineEdge?(edge)
            },
            findAugmentingPath: { path in
                self.findAugmentingPath?(path)
                other.findAugmentingPath?(path)
            },
            augmentMatching: { path in
                self.augmentMatching?(path)
                other.augmentMatching?(path)
            },
            updateMatching: { left, right in
                self.updateMatching?(left, right)
                other.updateMatching?(left, right)
            },
            startIteration: { iteration in
                self.startIteration?(iteration)
                other.startIteration?(iteration)
            }
        )
    }
}
#endif
