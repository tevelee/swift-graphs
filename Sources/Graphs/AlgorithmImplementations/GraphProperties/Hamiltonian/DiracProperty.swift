import Foundation

struct DiracProperty<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph> where Graph.VertexDescriptor: Hashable {
    struct Visitor {
        var insufficientVertices: ((Int) -> Void)?
        var checkMinimumDegree: ((Int) -> Void)?
        var checkVertexDegree: ((Graph.VertexDescriptor, Int, Int) -> Void)?
        var degreeTooLow: ((Graph.VertexDescriptor, Int, Int) -> Void)?
    }
}

extension DiracProperty.Visitor: Composable {
    func combined(with other: DiracProperty<Graph>.Visitor) -> DiracProperty<Graph>.Visitor {
        DiracProperty.Visitor(
            insufficientVertices: self.insufficientVertices ?? other.insufficientVertices,
            checkMinimumDegree: self.checkMinimumDegree ?? other.checkMinimumDegree,
            checkVertexDegree: self.checkVertexDegree ?? other.checkVertexDegree,
            degreeTooLow: self.degreeTooLow ?? other.degreeTooLow
        )
    }
}
