extension Graph where Self: IncidenceGraph & VertexListGraph, VertexDescriptor: Hashable {
    func traverse(
        from source: VertexDescriptor,
        using algorithm: some TraversalAlgorithm<Self>
    ) -> TraversalResult<VertexDescriptor, EdgeDescriptor> {
        algorithm.traverse(from: source, in: self)
    }
}

protocol TraversalAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph & VertexListGraph

    func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor>
}

struct TraversalResult<Vertex, Edge> {
    let vertices: [Vertex]
    let edges: [Edge]
}
