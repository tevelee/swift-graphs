extension TreePropertyAlgorithm {
    static func singlePass<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>() -> Self where Self == DFSTreePropertyAlgorithm<Graph> {
        .init()
    }
}

extension DFSTreePropertyAlgorithm: TreePropertyAlgorithm {}
