extension TraversalAlgorithm {
    static func dfs<Graph>(order: DFSOrder<Graph> = .preorder) -> Self where Self == DFSTraversal<Graph> {
        .init(order: order)
    }
}

struct DFSTraversal<Graph: IncidenceGraph>: TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    let order: DFSOrder<Graph>
    func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        DepthFirstSearch(on: graph, from: source)
            .withVisitor { order.makeVisitor(graph) }
            .forEach { _ in }
        
        return TraversalResult(
            vertices: order.vertices(),
            edges: order.edges()
        )
    }
}
