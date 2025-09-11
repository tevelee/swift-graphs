struct CostDefinition<Graph: Graphs.Graph, Cost> {
    let costToExplore: (Graph.EdgeDescriptor, Graph) -> Cost
}

extension CostDefinition {
    static func uniform(_ value: Cost) -> Self {
        .init { _, _ in value }
    }
}

extension CostDefinition where Graph: EdgePropertyGraph {
    static func property(_ extract: @escaping (EdgeProperties) -> Cost) -> Self {
        .init { edge, graph in
            extract(graph[edge])
        }
    }
}
