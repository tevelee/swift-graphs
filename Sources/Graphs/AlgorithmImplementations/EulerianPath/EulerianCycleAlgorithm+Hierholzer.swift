extension EulerianCycleAlgorithm {
    static func hierholzer<Graph>() -> Self where Self == Hierholzer<Graph> {
        .init()
    }
}

extension Hierholzer: EulerianCycleAlgorithm {
    func eulerianCycle(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        eulerianCycle(in: graph, visitor: nil)
    }
}
