extension EulerianPathAlgorithm {
    static func hierholzer<Graph>() -> Self where Self == Hierholzer<Graph> {
        .init()
    }
}

extension Hierholzer: EulerianPathAlgorithm {
    func eulerianPath(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        eulerianPath(in: graph, visitor: nil)
    }
}