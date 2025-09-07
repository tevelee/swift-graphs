extension TraversalAlgorithm {
    static func dfs<Graph>(order: DFSOrder<Graph> = .preorder) -> Self where Self == DFSTraversal<Graph> {
        .init(order: order)
    }
}

struct DFSTraversal<Graph: IncidenceGraph & VertexListGraph>: TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    let order: DFSOrder<Graph>
    func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        DepthFirstSearchAlgorithm(on: graph, from: source)
            .withVisitor { order.visitor }
            .forEach { _ in }
        
        return TraversalResult(
            vertices: order.vertices(),
            edges: order.edges()
        )
    }
}
