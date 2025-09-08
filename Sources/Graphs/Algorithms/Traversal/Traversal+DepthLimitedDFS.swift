extension TraversalAlgorithm {
    static func depthLimitedDFS<Graph>(maxDepth: UInt) -> Self where Self == DepthLimitedDFSTraversal<Graph> {
        .init(maxDepth: maxDepth)
    }
}

struct DepthLimitedDFSTraversal<Graph: IncidenceGraph & VertexListGraph>: TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    let maxDepth: UInt
    func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        var vertices: [Graph.VertexDescriptor] = []
        var edges: [Graph.EdgeDescriptor] = []
        let visitor = DepthFirstSearchAlgorithm<Graph>.Visitor(
            discoverVertex: { v in vertices.append(v) },
            treeEdge: { e in edges.append(e) },
            shouldTraverse: { args in
                guard let depth = args.context.depth(of: args.from) else { return true }
                return depth < maxDepth
            }
        )

        DepthFirstSearchAlgorithm(on: graph, from: source)
            .withVisitor { visitor }
            .forEach { _ in }
        return TraversalResult(vertices: vertices, edges: edges)
    }
}


