import Foundation

/// Extension providing composition support for depth-first search visitors.
extension DepthFirstSearch.Visitor: Composable {
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
            examineVertex: { vertex in
                self.examineVertex?(vertex)
                other.examineVertex?(vertex)
            },
            examineEdge: { edge in
                self.examineEdge?(edge)
                other.examineEdge?(edge)
            },
            treeEdge: { edge in
                self.treeEdge?(edge)
                other.treeEdge?(edge)
            },
            backEdge: { edge in
                self.backEdge?(edge)
                other.backEdge?(edge)
            },
            forwardEdge: { edge in
                self.forwardEdge?(edge)
                other.forwardEdge?(edge)
            },
            crossEdge: { edge in
                self.crossEdge?(edge)
                other.crossEdge?(edge)
            },
            finishVertex: { vertex in
                self.finishVertex?(vertex)
                other.finishVertex?(vertex)
            },
            shouldTraverse: { context in
                if let shouldTraverse = self.shouldTraverse, !shouldTraverse(context) {
                    return false
                }
                if let shouldTraverse = other.shouldTraverse, !shouldTraverse(context) {
                    return false
                }
                return true
            }
        )
    }
}
