extension TraversalAlgorithm {
    static func depthLimitedDFS<Graph>(maxDepth: UInt) -> Self where Self == DepthLimitedDFSTraversal<Graph> {
        .init(maxDepth: maxDepth)
    }
}

struct DepthLimitedDFSTraversal<Graph: IncidenceGraph>: TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    typealias Visitor = DepthFirstSearch<Graph>.Visitor
    
    let maxDepth: UInt
    func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        var vertices: [Graph.VertexDescriptor] = []
        var edges: [Graph.EdgeDescriptor] = []
        DepthFirstSearch(on: graph, from: source)
            .withVisitor {
                .init(
                    discoverVertex: { v in vertices.append(v) },
                    treeEdge: { e in edges.append(e) },
                    shouldTraverse: { args in
                        guard let depth = args.context.depth(of: args.from) else { return true }
                        return depth < maxDepth
                    }
                )
            }
            .withVisitor {
                visitor
            }
            .forEach { _ in }
        return TraversalResult(vertices: vertices, edges: edges)
    }
}

extension DepthLimitedDFSTraversal: VisitorSupporting {}
