extension Graph where Self: IncidenceGraph & VertexListGraph & EdgePropertyGraph, VertexDescriptor: Equatable {
    func shortestPath<Weight: Comparable>(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        using algorithm: some ShortestPathAlgorithm<VertexDescriptor, EdgeDescriptor, Weight>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.shortestPath(from: source, to: destination, in: self)
    }
}

protocol ShortestPathAlgorithm<Vertex, Edge, Weight> {
    associatedtype Vertex: Equatable
    associatedtype Edge
    associatedtype Weight: Comparable

    func shortestPath(
        from source: Vertex,
        to destination: Vertex,
        in graph: some Graph<Vertex, Edge> & IncidenceGraph & VertexListGraph & EdgePropertyGraph
    ) -> Path<Vertex, Edge>?
}

extension ShortestPathAlgorithm where Self: ShortestPathUntilAlgorithm, Vertex: Equatable {
    func shortestPath(
        from source: Vertex,
        to destination: Vertex,
        in graph: some Graph<Vertex, Edge> & IncidenceGraph & VertexListGraph & EdgePropertyGraph
    ) -> Path<Vertex, Edge>? {
        shortestPath(from: source, until: { $0 == destination }, in: graph)
    }
}
