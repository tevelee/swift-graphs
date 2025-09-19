extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func stronglyConnectedComponents(
        using algorithm: TarjanStronglyConnectedComponentsAlgorithm<Self>
    ) -> StronglyConnectedComponentsResult<VertexDescriptor> {
        algorithm.stronglyConnectedComponents(in: self, visitor: nil as Tarjan<Self>.Visitor?)
    }
}
