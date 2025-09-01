extension Graph where Self: IncidenceGraph & VertexListGraph & EdgePropertyGraph {
    func shortestPath<Weight: Comparable>(
        from source: VertexDescriptor,
        until condition: @escaping (VertexDescriptor) -> Bool,
        using algorithm: some ShortestPathUntilAlgorithm<VertexDescriptor, EdgeDescriptor, Weight>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.shortestPath(from: source, until: condition, in: self)
    }
}

protocol ShortestPathUntilAlgorithm<Vertex, Edge, Weight> {
    associatedtype Vertex
    associatedtype Edge
    associatedtype Weight: Comparable

    func shortestPath(
        from source: Vertex,
        until condition: @escaping (Vertex) -> Bool,
        in graph: some Graph<Vertex, Edge> & IncidenceGraph & VertexListGraph & EdgePropertyGraph
    ) -> Path<Vertex, Edge>?
}
