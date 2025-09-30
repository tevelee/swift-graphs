extension TraversalAlgorithm {
    @inlinable
    public static func dfs<Graph>(order: DFSOrder<Graph> = .preorder) -> Self where Self == DFSTraversal<Graph> {
        .init(order: order)
    }
}

public struct DFSTraversal<Graph: IncidenceGraph>: TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Visitor = DepthFirstSearch<Graph>.Visitor
    
    public let order: DFSOrder<Graph>
    
    @inlinable
    public init(order: DFSOrder<Graph>) {
        self.order = order
    }
    
    @inlinable
    public func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        var edges: [Graph.EdgeDescriptor] = []
        let vertices = SharedBuffer<Graph.VertexDescriptor>()

        DepthFirstSearch(on: graph, from: source)
            .withVisitor { order.makeVisitor(graph, vertices) }
            .withVisitor { .init(examineEdge: { edges.append($0) }) }
            .withVisitor { visitor }
            .forEach { _ in }

        return TraversalResult(
            vertices: vertices.elements,
            edges: edges
        )
    }
}

extension DFSTraversal: VisitorSupporting {}
