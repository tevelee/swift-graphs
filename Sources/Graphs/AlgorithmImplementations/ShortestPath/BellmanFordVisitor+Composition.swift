#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
/// Extension providing composition support for Bellman-Ford algorithm visitors.
extension BellmanFord.Visitor: Composable {
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
            edgeRelaxed: { edge in
                self.edgeRelaxed?(edge)
                other.edgeRelaxed?(edge)
            },
            edgeNotRelaxed: { edge in
                self.edgeNotRelaxed?(edge)
                other.edgeNotRelaxed?(edge)
            },
            detectNegativeCycle: { edge in
                self.detectNegativeCycle?(edge)
                other.detectNegativeCycle?(edge)
            },
            completeRelaxationIteration: { iteration in
                self.completeRelaxationIteration?(iteration)
                other.completeRelaxationIteration?(iteration)
            }
        )
    }
}
#endif
