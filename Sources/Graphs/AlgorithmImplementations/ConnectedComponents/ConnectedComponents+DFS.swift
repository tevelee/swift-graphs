extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func connectedComponents(
        using algorithm: DFSConnectedComponentsAlgorithm<Self>
    ) -> [[VertexDescriptor]] {
        algorithm.connectedComponents(in: self, visitor: nil)
    }
}
