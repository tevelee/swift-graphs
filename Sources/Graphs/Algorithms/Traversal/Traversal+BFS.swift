extension TraversalAlgorithm where Vertex: Hashable {
    static func bfs<Vertex, Edge>() -> Self where Self == BFSTraversal<Vertex, Edge> {
        .init()
    }
}

struct BFSTraversal<Vertex: Hashable, Edge>: TraversalAlgorithm {
    func traverse(
        from source: Vertex,
        in graph: some Graph<Vertex, Edge> & IncidenceGraph & VertexListGraph
    ) -> TraversalResult<Vertex, Edge> {
        var vertices: [Vertex] = []
        var edges: [Edge] = []

        BreadthFirstSearchAlgorithm.run(
            on: graph,
            from: source,
            visitor: .init(
                examineVertex: { vertex in
                    vertices.append(vertex)
                },
                examineEdge: { edge in
                    edges.append(edge)
                }
            )
        )
        
        return TraversalResult(
            vertices: vertices,
            edges: edges
        )
    }
}
