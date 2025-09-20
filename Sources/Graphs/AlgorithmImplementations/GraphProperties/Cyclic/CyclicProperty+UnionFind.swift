extension CyclicPropertyAlgorithm {
    static func unionFind<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>() -> Self where Self == UnionFindCyclicPropertyAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}

extension UnionFindCyclicPropertyAlgorithm: CyclicPropertyAlgorithm {}
