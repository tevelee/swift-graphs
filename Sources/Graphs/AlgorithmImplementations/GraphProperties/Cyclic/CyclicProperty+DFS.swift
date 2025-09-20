extension CyclicPropertyAlgorithm {
    static func dfs<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == DFSCyclicPropertyAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}

extension DFSCyclicPropertyAlgorithm: CyclicPropertyAlgorithm {}
