extension Graph where Self: IncidenceGraph & VertexListGraph, VertexDescriptor: Hashable {
    func traverse(
        from source: VertexDescriptor,
        using algorithm: some TraversalAlgorithm<VertexDescriptor, EdgeDescriptor>
    ) -> TraversalResult<VertexDescriptor, EdgeDescriptor> {
        algorithm.traverse(from: source, in: self)
    }
}

protocol TraversalAlgorithm<Vertex, Edge> {
    associatedtype Vertex: Hashable
    associatedtype Edge

    func traverse(
        from source: Vertex,
        in graph: some Graph<Vertex, Edge> & IncidenceGraph & VertexListGraph
    ) -> TraversalResult<Vertex, Edge>
}

struct TraversalResult<Vertex, Edge> {
    let vertices: [Vertex]
    let edges: [Edge]
}
