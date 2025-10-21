/// Extension providing composition support for breadth-first search visitors.
extension BreadthFirstSearch.Visitor: Composable {
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
            nonTreeEdge: { edge in
                self.nonTreeEdge?(edge)
                other.nonTreeEdge?(edge)
            },
            grayTargetEdge: { edge in
                self.grayTargetEdge?(edge)
                other.grayTargetEdge?(edge)
            },
            blackTargetEdge: { edge in
                self.blackTargetEdge?(edge)
                other.blackTargetEdge?(edge)
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
