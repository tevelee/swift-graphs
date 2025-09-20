import Foundation

extension LeftRightPlanarPropertyAlgorithm.Visitor: Composable {
    func combined(with other: LeftRightPlanarPropertyAlgorithm.Visitor) -> LeftRightPlanarPropertyAlgorithm.Visitor {
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
