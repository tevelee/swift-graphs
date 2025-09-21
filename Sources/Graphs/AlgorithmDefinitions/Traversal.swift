extension Graph where Self: IncidenceGraph, VertexDescriptor: Hashable {
    func traverse(
        from source: VertexDescriptor,
        using algorithm: some TraversalAlgorithm<Self>
    ) -> TraversalResult<VertexDescriptor, EdgeDescriptor> {
        algorithm.traverse(from: source, in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension Graph where Self: IncidenceGraph, VertexDescriptor: Hashable {
    func traverse(from source: VertexDescriptor) -> TraversalResult<VertexDescriptor, EdgeDescriptor> {
        traverse(from: source, using: .dfs())
    }
}

protocol TraversalAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph
    associatedtype Visitor

    func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor>
}

struct TraversalResult<Vertex, Edge> {
    let vertices: [Vertex]
    let edges: [Edge]
}

extension VisitorWrapper: TraversalAlgorithm where Base: TraversalAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    typealias Graph = Base.Graph
    
    func traverse(
        from source: Base.Graph.VertexDescriptor,
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> TraversalResult<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor> {
        base.traverse(from: source, in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
