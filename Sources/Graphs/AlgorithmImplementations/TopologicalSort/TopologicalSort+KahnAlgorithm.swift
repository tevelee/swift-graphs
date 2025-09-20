extension TopologicalSortAlgorithm {
    static func kahn<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == Kahn<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}
