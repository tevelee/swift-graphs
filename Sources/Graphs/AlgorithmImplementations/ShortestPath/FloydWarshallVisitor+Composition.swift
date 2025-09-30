import Foundation

/// Extension providing composition support for Floyd-Warshall algorithm visitors.
extension FloydWarshall.Visitor: Composable {
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
            updateDistance: { from, to, distance in
                self.updateDistance?(from, to, distance)
                other.updateDistance?(from, to, distance)
            },
            completeIntermediateVertex: { vertex in
                self.completeIntermediateVertex?(vertex)
                other.completeIntermediateVertex?(vertex)
            }
        )
    }
}
