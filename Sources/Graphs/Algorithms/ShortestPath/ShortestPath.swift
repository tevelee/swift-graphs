extension IncidenceGraph where VertexDescriptor: Equatable {
    func shortestPath<Weight: Comparable>(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        using algorithm: some ShortestPathAlgorithm<Self, Weight>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.shortestPath(from: source, to: destination, in: self)
    }
}

protocol ShortestPathAlgorithm<Graph, Weight> {
    associatedtype Graph: IncidenceGraph
    associatedtype Weight: Comparable

    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}

extension ShortestPathAlgorithm where Self: ShortestPathUntilAlgorithm, Graph.VertexDescriptor: Equatable {
    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        shortestPath(from: source, until: { $0 == destination }, in: graph)
    }
}
