extension BidirectionalGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func stronglyConnectedComponents(
        using algorithm: KosarajuStronglyConnectedComponentsAlgorithm<Self>
    ) -> StronglyConnectedComponentsResult<VertexDescriptor> {
        algorithm.stronglyConnectedComponents(in: self, visitor: nil as Kosaraju<Self>.Visitor?)
    }
}
