extension SearchAlgorithm {
    static func dfs<Graph>() -> Self where Self == DFSSearch<Graph> {
        .init()
    }
}

struct DFSSearch<Graph: IncidenceGraph>: SearchAlgorithm where Graph.VertexDescriptor: Hashable {
    func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> DepthFirstSearch<Graph> {
        DepthFirstSearch(on: graph, from: source)
    }
}
