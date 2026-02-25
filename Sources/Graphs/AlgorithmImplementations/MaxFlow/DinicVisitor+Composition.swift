#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
/// Extension providing composition support for Dinic's algorithm visitors.
extension Dinic.Visitor: Composable {
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: Self) -> Self {
        .init(
            examineEdge: { edge, flow in
                self.examineEdge?(edge, flow)
                other.examineEdge?(edge, flow)
            },
            augmentPath: { edges, flow in
                self.augmentPath?(edges, flow)
                other.augmentPath?(edges, flow)
            },
            updateFlow: { edge, flow in
                self.updateFlow?(edge, flow)
                other.updateFlow?(edge, flow)
            },
            buildLevelGraph: {
                self.buildLevelGraph?()
                other.buildLevelGraph?()
            },
            findBlockingFlow: {
                self.findBlockingFlow?()
                other.findBlockingFlow?()
            },
            levelAssigned: { vertex, level in
                self.levelAssigned?(vertex, level)
                other.levelAssigned?(vertex, level)
            },
            edgeBlocked: { edge in
                self.edgeBlocked?(edge)
                other.edgeBlocked?(edge)
            }
        )
    }
}
#endif
