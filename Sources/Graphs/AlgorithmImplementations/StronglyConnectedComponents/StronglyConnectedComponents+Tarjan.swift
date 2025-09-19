extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func stronglyConnectedComponents(
        using algorithm: TarjanStronglyConnectedComponentsAlgorithm<Self>
    ) -> [[VertexDescriptor]] {
        algorithm.stronglyConnectedComponents(in: self, visitor: nil)
    }
}
