extension TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    static func bestFirst<Graph, HScore>(
        heuristic: Heuristic<Graph, HScore>
    ) -> Self where Self == BestFirstTraversal<Graph, HScore> {
        .init(heuristic: heuristic)
    }
}

struct BestFirstTraversal<Graph: IncidenceGraph & VertexListGraph & EdgePropertyGraph, HScore: Numeric & Comparable>: TraversalAlgorithm where Graph.VertexDescriptor: Hashable, HScore.Magnitude == HScore {
    let heuristic: Heuristic<Graph, HScore>

    func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        var vertices: [Graph.VertexDescriptor] = []
        var edges: [Graph.EdgeDescriptor] = []

        AStarAlgorithm(
            on: graph,
            from: source,
            edgeWeight: .uniform(0),
            heuristic: heuristic,
            calculateTotalCost: { $1 }
        )
        .withVisitor {
            .init(
                examineVertex: { vertex in
                    vertices.append(vertex)
                },
                edgeRelaxed: { edge in
                    edges.append(edge)
                }
            )
        }
        .forEach { _ in }

        return TraversalResult(vertices: vertices, edges: edges)
    }
}


