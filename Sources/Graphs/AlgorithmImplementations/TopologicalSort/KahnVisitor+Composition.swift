#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
/// Extension providing composition support for Kahn's algorithm visitors.
extension Kahn.Visitor: Composable {
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: Self) -> Self {
        .init(
            discoverVertex: { vertex in
                self.discoverVertex?(vertex)
                other.discoverVertex?(vertex)
            },
            examineEdge: { edge in
                self.examineEdge?(edge)
                other.examineEdge?(edge)
            },
            finishVertex: { vertex in
                self.finishVertex?(vertex)
                other.finishVertex?(vertex)
            },
            detectCycle: { vertices in
                self.detectCycle?(vertices)
                other.detectCycle?(vertices)
            }
        )
    }
}
#endif
