extension TopologicalSortAlgorithm {
    static func dfs<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == DFSTopologicalSort<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}
