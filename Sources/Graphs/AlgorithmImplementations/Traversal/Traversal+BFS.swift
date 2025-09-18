extension TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    static func bfs<Graph>() -> Self where Self == BFSTraversal<Graph> {
        .init()
    }
}

struct BFSTraversal<Graph: IncidenceGraph>: TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    typealias Visitor = BreadthFirstSearch<Graph>.Visitor
    
    func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
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
            .withVisitor {
                visitor
            }
            .forEach { _ in }
        
        return TraversalResult(
            vertices: vertices,
            edges: edges
        )
    }
}

extension BFSTraversal: VisitorSupporting {}
