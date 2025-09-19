extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func connectedComponents(
        using algorithm: DFSConnectedComponentsAlgorithm<Self>
    ) -> ConnectedComponentsResult<VertexDescriptor> {
        algorithm.connectedComponents(in: self, visitor: nil)
    }
}
