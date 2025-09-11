extension Graph where Self: IncidenceGraph, VertexDescriptor: Hashable {
    func search<Algorithm: SearchAlgorithm>(
        from source: VertexDescriptor,
        using algorithm: Algorithm
    ) -> Algorithm.SearchSequence where Algorithm.Graph == Self {
        algorithm.search(from: source, in: self)
    }
}

protocol SearchAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    associatedtype SearchSequence: Sequence

    func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> SearchSequence
}
