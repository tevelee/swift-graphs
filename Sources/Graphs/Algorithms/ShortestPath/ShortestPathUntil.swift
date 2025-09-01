extension Graph where Self: IncidenceGraph & VertexListGraph & EdgePropertyGraph {
    func shortestPath<Cost: Comparable>(
        from source: VertexDescriptor,
        until condition: @escaping (VertexDescriptor) -> Bool,
        cost: (EdgePropertyValues) -> Cost,
        using algorithm: some ShortestPathUntilAlgorithm<VertexDescriptor, EdgeDescriptor, Cost>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.shortestPath(from: source, until: condition, cost: cost, in: self)
    }
}

protocol ShortestPathUntilAlgorithm<Vertex, Edge, Cost> {
    associatedtype Vertex
    associatedtype Edge
    associatedtype Cost: Comparable

    func shortestPath(
        from source: Vertex,
        until condition: @escaping (Vertex) -> Bool,
        cost: (EdgePropertyValues) -> Cost,
        in graph: some Graph<Vertex, Edge> & IncidenceGraph & VertexListGraph & EdgePropertyGraph
    ) -> Path<Vertex, Edge>?
}
