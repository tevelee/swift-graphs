import Foundation

/// Extension providing composition support for greedy coloring algorithm visitors.
extension GreedyColoringAlgorithm.Visitor: Composable {
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
            assignColor: { vertex, color in
                self.assignColor?(vertex, color)
                other.assignColor?(vertex, color)
            },
            skipVertex: { vertex, reason in
                self.skipVertex?(vertex, reason)
                other.skipVertex?(vertex, reason)
            }
        )
    }
}
