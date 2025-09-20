import Foundation

struct OreProperty<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph> where Graph.VertexDescriptor: Hashable {
    struct Visitor {
        var insufficientVertices: ((Int) -> Void)?
        var checkVertexCount: ((Int) -> Void)?
        var checkVertexPair: ((Graph.VertexDescriptor, Graph.VertexDescriptor, Bool) -> Void)?
        var checkDegreeSum: ((Graph.VertexDescriptor, Graph.VertexDescriptor, Int, Int) -> Void)?
        var degreeSumTooLow: ((Graph.VertexDescriptor, Graph.VertexDescriptor, Int, Int) -> Void)?
    }
}

extension OreProperty.Visitor: Composable {
    func combined(with other: OreProperty<Graph>.Visitor) -> OreProperty<Graph>.Visitor {
        OreProperty.Visitor(
            insufficientVertices: self.insufficientVertices ?? other.insufficientVertices,
            checkVertexCount: self.checkVertexCount ?? other.checkVertexCount,
            checkVertexPair: self.checkVertexPair ?? other.checkVertexPair,
            checkDegreeSum: self.checkDegreeSum ?? other.checkDegreeSum,
            degreeSumTooLow: self.degreeSumTooLow ?? other.degreeSumTooLow
        )
    }
}
