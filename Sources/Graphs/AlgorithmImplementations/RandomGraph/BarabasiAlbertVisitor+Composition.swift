import Foundation

/// Extension providing composition support for Barabasi-Albert random graph algorithm visitors.
extension BarabasiAlbert.Visitor: Composable {
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: Self) -> Self {
        .init(
            addVertex: { vertex in
                self.addVertex?(vertex)
                other.addVertex?(vertex)
            },
            addEdge: { from, to in
                self.addEdge?(from, to)
                other.addEdge?(from, to)
            },
            selectTarget: { vertex, candidates in
                self.selectTarget?(vertex, candidates)
                other.selectTarget?(vertex, candidates)
            },
            updateDegree: { vertex, degree in
                self.updateDegree?(vertex, degree)
                other.updateDegree?(vertex, degree)
            }
        )
    }
}
