struct CostAlgorithm<Graph: Graphs.Graph, Cost> {
    let costToExplore: (Graph.EdgeDescriptor, Graph) -> Cost
}

extension CostAlgorithm {
    static func uniform(_ value: Cost = 1) -> Self {
        .init { _, _ in value }
    }
}

extension CostAlgorithm where Graph: PropertyGraph {
    static func property(_ extract: @escaping (EdgePropertyValues) -> Cost) -> Self {
        .init { edge, graph in
            extract(graph[edge])
        }
    }
}
