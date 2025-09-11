extension SearchAlgorithm {
    static func bfs<Graph>() -> Self where Self == BFSSearch<Graph> {
        .init()
    }
}

struct BFSSearch<Graph: IncidenceGraph>: SearchAlgorithm where Graph.VertexDescriptor: Hashable {
    func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> BreadthFirstSearch<Graph> {
        BreadthFirstSearch(on: graph, from: source)
    }
}
