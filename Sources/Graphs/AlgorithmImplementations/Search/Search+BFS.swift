extension SearchAlgorithm {
    static func bfs<Graph>() -> Self where Self == BFSSearch<Graph> {
        .init()
    }
}

struct BFSSearch<Graph: IncidenceGraph>: SearchAlgorithm where Graph.VertexDescriptor: Hashable {
    typealias Visitor = BreadthFirstSearch<Graph>.Visitor
    
    func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> BreadthFirstSearch<Graph> {
        BreadthFirstSearch(on: graph, from: source)
    }
}

extension BFSSearch: VisitorSupporting {}
