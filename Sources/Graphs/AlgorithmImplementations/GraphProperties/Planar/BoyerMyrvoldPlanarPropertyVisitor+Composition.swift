import Foundation

/// Extension providing composition support for Boyer-Myrvold planar property algorithm visitors.
extension BoyerMyrvoldPlanarPropertyAlgorithm.Visitor: Composable {
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: BoyerMyrvoldPlanarPropertyAlgorithm.Visitor) -> BoyerMyrvoldPlanarPropertyAlgorithm.Visitor {
        BoyerMyrvoldPlanarPropertyAlgorithm.Visitor(
            startEmbedding: {
                self.startEmbedding?()
                other.startEmbedding?()
            },
            examineVertex: { vertex, time in
                self.examineVertex?(vertex, time)
                other.examineVertex?(vertex, time)
            },
            examineEdge: { edge, type in
                self.examineEdge?(edge, type)
                other.examineEdge?(edge, type)
            },
            addToEmbedding: { vertex, neighbors in
                self.addToEmbedding?(vertex, neighbors)
                other.addToEmbedding?(vertex, neighbors)
            },
            checkBiconnected: {
                self.checkBiconnected?()
                other.checkBiconnected?()
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
