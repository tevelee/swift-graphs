extension Graph where Self: IncidenceGraph & VertexListGraph & EdgePropertyGraph {
    func shortestPath<Weight: Comparable>(
        from source: VertexDescriptor,
        until condition: @escaping (VertexDescriptor) -> Bool,
        weight: (EdgePropertyValues) -> Weight,
        using algorithm: some ShortestPathUntilAlgorithm<VertexDescriptor, EdgeDescriptor, Weight>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.shortestPath(from: source, until: condition, weight: weight, in: self)
    }
}

protocol ShortestPathUntilAlgorithm<Vertex, Edge, Weight> {
    associatedtype Vertex
    associatedtype Edge
    associatedtype Weight: Comparable

    func shortestPath(
        from source: Vertex,
        until condition: @escaping (Vertex) -> Bool,
        weight: (EdgePropertyValues) -> Weight,
        in graph: some Graph<Vertex, Edge> & IncidenceGraph & VertexListGraph & EdgePropertyGraph
    ) -> Path<Vertex, Edge>?
}
