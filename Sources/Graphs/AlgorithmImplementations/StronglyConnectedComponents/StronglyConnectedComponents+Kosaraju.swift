extension BidirectionalGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func stronglyConnectedComponents(
        using algorithm: KosarajuStronglyConnectedComponentsAlgorithm<Self>
    ) -> [[VertexDescriptor]] {
        algorithm.stronglyConnectedComponents(in: self, visitor: nil)
    }
}
