// Inorder DFS specialized for binary graphs (left, visit, right)

struct BinaryDFSTraversal<Graph: IncidenceGraph & BinaryIncidenceGraph & VertexListGraph>: TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    let order: BinaryDFSOrder<Graph>

    func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        switch order.kind {
        case .inorder:
            return inorder(from: source, in: graph)
        }
    }

    private func inorder(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        var visited: Set<Graph.VertexDescriptor> = []
        var stack: [Graph.VertexDescriptor] = []
        var current: Graph.VertexDescriptor? = source

        var vertices: [Graph.VertexDescriptor] = []
        var edges: [Graph.EdgeDescriptor] = []

        while current != nil || !stack.isEmpty {
            while let v = current, visited.contains(v) == false {
                stack.append(v)
                visited.insert(v)
                if let left = graph.leftNeighbor(of: v) {
                    if let e = graph.leftEdge(of: v) { edges.append(e) }
                    current = left
                } else {
                    current = nil
                }
            }

            guard let node = stack.popLast() else { break }
            vertices.append(node)

            if let right = graph.rightNeighbor(of: node), visited.contains(right) == false {
                if let e = graph.rightEdge(of: node) { edges.append(e) }
                current = right
            } else {
                current = nil
            }
        }

        return TraversalResult(vertices: vertices, edges: edges)
    }
}

struct BinaryDFSOrder<Graph: IncidenceGraph & BinaryIncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    enum Kind { case inorder }
    let kind: Kind

    static var inorder: Self { .init(kind: .inorder) }
}

extension TraversalAlgorithm {
    static func dfs<Graph>(order: BinaryDFSOrder<Graph>) -> Self where
        Self == BinaryDFSTraversal<Graph>,
        Graph: IncidenceGraph & BinaryIncidenceGraph & VertexListGraph,
        Graph.VertexDescriptor: Hashable
    {
        .init(order: order)
    }
}


