extension SearchAlgorithm {
    static func dfs<Graph>() -> Self where Self == DFSSearch<Graph> {
        .init()
    }
}

struct DFSSearch<Graph: IncidenceGraph>: SearchAlgorithm where Graph.VertexDescriptor: Hashable {
    typealias Visitor = DepthFirstSearch<Graph>.Visitor
    
    func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> DepthFirstSearch<Graph> {
        DepthFirstSearch(on: graph, from: source)
    }
}

extension DFSSearch: VisitorSupporting {}
