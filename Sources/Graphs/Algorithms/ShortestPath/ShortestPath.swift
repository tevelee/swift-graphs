extension Graph where Self: IncidenceGraph & VertexListGraph & EdgePropertyGraph, VertexDescriptor: Equatable {
    func shortestPath<Cost: Comparable>(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        cost: (EdgePropertyValues) -> Cost,
        using algorithm: some ShortestPathAlgorithm<VertexDescriptor, EdgeDescriptor, Cost>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.shortestPath(from: source, to: destination, cost: cost, in: self)
    }
}

protocol ShortestPathAlgorithm<Vertex, Edge, Cost> {
    associatedtype Vertex: Equatable
    associatedtype Edge
    associatedtype Cost: Comparable

    func shortestPath(
        from source: Vertex,
        to destination: Vertex,
        cost: (EdgePropertyValues) -> Cost,
        in graph: some Graph<Vertex, Edge> & IncidenceGraph & VertexListGraph & EdgePropertyGraph
    ) -> Path<Vertex, Edge>?
}

extension ShortestPathAlgorithm where Self: ShortestPathUntilAlgorithm, Vertex: Equatable {
    func shortestPath(
        from source: Vertex,
        to destination: Vertex,
        cost: (EdgePropertyValues) -> Cost,
        in graph: some Graph<Vertex, Edge> & IncidenceGraph & VertexListGraph & EdgePropertyGraph
    ) -> Path<Vertex, Edge>? {
        shortestPath(from: source, until: { $0 == destination }, cost: cost, in: graph)
    }
}
