extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func connectedComponents(
        using algorithm: UnionFindConnectedComponentsAlgorithm<Self>
    ) -> [[VertexDescriptor]] {
        algorithm.connectedComponents(in: self, visitor: nil)
    }
}
