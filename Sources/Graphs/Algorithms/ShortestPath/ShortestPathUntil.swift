extension IncidenceGraph {
    func shortestPath(
        from source: VertexDescriptor,
        until condition: @escaping (VertexDescriptor) -> Bool,
        using algorithm: some ShortestPathUntilAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.shortestPath(from: source, until: condition, in: self)
    }
}

protocol ShortestPathUntilAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph

    func shortestPath(
        from source: Graph.VertexDescriptor,
        until condition: @escaping (Graph.VertexDescriptor) -> Bool,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}
