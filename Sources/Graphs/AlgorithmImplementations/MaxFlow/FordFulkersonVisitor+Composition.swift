/// Extension providing composition support for Ford-Fulkerson algorithm visitors.
extension FordFulkerson.Visitor: Composable {
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
            findPath: { source, sink in
                self.findPath?(source, sink)
                other.findPath?(source, sink)
            }
        )
    }
}
