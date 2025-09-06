extension TraversalAlgorithm where Vertex: Hashable {
    static func dfs<Vertex, Edge>() -> Self where Self == DFSTraversal<Vertex, Edge> {
        .init()
    }
}

struct DFSTraversal<Vertex: Hashable, Edge>: TraversalAlgorithm {
    func traverse(
        from source: Vertex,
        in graph: some Graph<Vertex, Edge> & IncidenceGraph & VertexListGraph
    ) -> TraversalResult<Vertex, Edge> {
        var vertices: [Vertex] = []
        var edges: [Edge] = []

        DepthFirstSearchAlgorithm(on: graph, from: source)
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
