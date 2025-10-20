import Foundation

/// Extension providing composition support for Erdos-Renyi random graph algorithm visitors.
extension ErdosRenyi.Visitor: Composable {
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
            skipEdge: { from, to, reason in
                self.skipEdge?(from, to, reason)
                other.skipEdge?(from, to, reason)
            },
            examineVertexPair: { from, to in
                self.examineVertexPair?(from, to)
                other.examineVertexPair?(from, to)
            }
        )
    }
}
