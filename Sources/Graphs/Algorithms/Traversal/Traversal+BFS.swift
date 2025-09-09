extension TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    static func bfs<Graph>() -> Self where Self == BFSTraversal<Graph> {
        .init()
    }
}

struct BFSTraversal<Graph: IncidenceGraph & VertexListGraph>: TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        var vertices: [Graph.VertexDescriptor] = []
        var edges: [Graph.EdgeDescriptor] = []

        BreadthFirstSearch(on: graph, from: source)
            .withVisitor {
                .init(
                    examineVertex: { vertex in
                        vertices.append(vertex)
                    },
                    examineEdge: { edge in
                        edges.append(edge)
                    }
                )
            }
            .forEach { _ in }
        
        return TraversalResult(
            vertices: vertices,
            edges: edges
        )
    }
}
