struct TarjanStronglyConnectedComponentsAlgorithm<Graph: IncidenceGraph & VertexListGraph>: StronglyConnectedComponentsAlgorithm where Graph.VertexDescriptor: Hashable {
    typealias Visitor = Tarjan<Graph>.Visitor
    
    func stronglyConnectedComponents(
        in graph: Graph,
        visitor: Visitor?
    ) -> StronglyConnectedComponentsResult<Graph.VertexDescriptor> {
        let tarjan = Tarjan(on: graph)
        return tarjan.stronglyConnectedComponents(visitor: visitor)
    }
}

extension StronglyConnectedComponentsAlgorithm {
    static func tarjan<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == TarjanStronglyConnectedComponentsAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}
