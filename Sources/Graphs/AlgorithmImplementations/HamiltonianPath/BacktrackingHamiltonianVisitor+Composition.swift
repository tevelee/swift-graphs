import Foundation

/// Extension providing composition support for backtracking Hamiltonian path algorithm visitors.
extension BacktrackingHamiltonian.Visitor: Composable {
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
            addToPath: { vertex in
                self.addToPath?(vertex)
                other.addToPath?(vertex)
            },
            removeFromPath: { vertex in
                self.removeFromPath?(vertex)
                other.removeFromPath?(vertex)
            },
            backtrack: { vertex in
                self.backtrack?(vertex)
                other.backtrack?(vertex)
            }
        )
    }
}
