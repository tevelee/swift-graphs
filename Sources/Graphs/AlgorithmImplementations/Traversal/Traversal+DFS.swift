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
        var edges: [Graph.EdgeDescriptor] = []
        let edgeCollectingVisitor = DepthFirstSearch<Graph>.Visitor(examineEdge: { edges.append($0) })
        
        let vertices = SharedBuffer<Graph.VertexDescriptor>()
        let vertexCollectingVisitor = order.makeVisitor(graph, vertices)
        
        DepthFirstSearch(on: graph, from: source)
            .withVisitor { .composite(vertexCollectingVisitor, edgeCollectingVisitor) }
            .forEach { _ in }

        return TraversalResult(
            vertices: vertices.elements,
            edges: edges
        )
    }
}
