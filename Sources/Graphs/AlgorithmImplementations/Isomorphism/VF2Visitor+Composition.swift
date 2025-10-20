import Foundation

/// Extension providing composition support for VF2 isomorphism algorithm visitors.
extension VF2Isomorphism.Visitor: Composable {
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
            tryMapping: { vertex1, vertex2 in
                self.tryMapping?(vertex1, vertex2)
                other.tryMapping?(vertex1, vertex2)
            },
            mappingFound: { mapping in
                self.mappingFound?(mapping)
                other.mappingFound?(mapping)
            },
            backtrack: { vertex1, vertex2 in
                self.backtrack?(vertex1, vertex2)
                other.backtrack?(vertex1, vertex2)
            }
        )
    }
}
