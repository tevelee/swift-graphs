extension SearchAlgorithm {
    static func dfs<Graph>(order: DFSOrder<Graph>) -> Self where Self == DFSOrderedSearch<Graph> {
        .init(order: order)
    }
}

struct DFSOrderedSearch<Graph: IncidenceGraph>: SearchAlgorithm where Graph.VertexDescriptor: Hashable {
    let order: DFSOrder<Graph>
    
    func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> BufferedSequence<VisitorFactoryWrapper<DepthFirstSearch<Graph>, DepthFirstSearch<Graph>.Visitor>, Graph.VertexDescriptor> {
        .init(
            base: DepthFirstSearch(on: graph, from: source).withVisitor { .init() }
        ) { buffer, _ in
            let visitor: DepthFirstSearch<Graph>.Visitor = order.makeVisitor(graph, buffer)
            return DepthFirstSearch(on: graph, from: source).withVisitor { visitor }
        }
    }
}

