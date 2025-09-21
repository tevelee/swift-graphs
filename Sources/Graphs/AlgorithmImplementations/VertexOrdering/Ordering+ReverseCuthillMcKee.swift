extension VertexOrderingAlgorithm {
    static func reverseCuthillMcKee<G: IncidenceGraph & VertexListGraph & BidirectionalGraph>() -> Self where Self == ReverseCuthillMcKeeOrderingAlgorithm<G>, G.VertexDescriptor: Hashable {
        .init()
    }
}

extension ReverseCuthillMcKeeOrderingAlgorithm: VertexOrderingAlgorithm {}
