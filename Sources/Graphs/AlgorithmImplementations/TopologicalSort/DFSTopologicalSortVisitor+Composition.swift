/// Extension providing composition support for DFS topological sort visitors.
extension DFSTopologicalSort.Visitor: Composable {
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
            detectCycle: { vertices in
                self.detectCycle?(vertices)
                other.detectCycle?(vertices)
            }
        )
    }
}
