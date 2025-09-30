import Foundation

/// Extension providing composition support for Left-Right planar property algorithm visitors.
extension LeftRightPlanarPropertyAlgorithm.Visitor: Composable {
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: LeftRightPlanarPropertyAlgorithm.Visitor) -> LeftRightPlanarPropertyAlgorithm.Visitor {
        LeftRightPlanarPropertyAlgorithm.Visitor(
            startEmbedding: {
                self.startEmbedding?()
                other.startEmbedding?()
            },
            examineVertex: { vertex in
                self.examineVertex?(vertex)
                other.examineVertex?(vertex)
            },
            examineEdge: { edge in
                self.examineEdge?(edge)
                other.examineEdge?(edge)
            },
            addEdgeToEmbedding: { edge, order in
                self.addEdgeToEmbedding?(edge, order)
                other.addEdgeToEmbedding?(edge, order)
            },
            embeddingConflict: { edge1, edge2 in
                self.embeddingConflict?(edge1, edge2)
                other.embeddingConflict?(edge1, edge2)
            },
            embeddingSuccess: {
                self.embeddingSuccess?()
                other.embeddingSuccess?()
            },
            embeddingFailure: {
                self.embeddingFailure?()
                other.embeddingFailure?()
            }
        )
    }
}
