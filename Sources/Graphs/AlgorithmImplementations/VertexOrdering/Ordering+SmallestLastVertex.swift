extension VertexOrderingAlgorithm {
    static func smallestLastVertex<G: IncidenceGraph & VertexListGraph & BidirectionalGraph>() -> Self where Self == SmallestLastVertexOrderingAlgorithm<G>, G.VertexDescriptor: Hashable {
        .init()
    }
}

extension SmallestLastVertexOrderingAlgorithm: VertexOrderingAlgorithm {}
