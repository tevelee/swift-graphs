struct KosarajuStronglyConnectedComponentsAlgorithm<Graph: BidirectionalGraph & VertexListGraph>: StronglyConnectedComponentsAlgorithm where Graph.VertexDescriptor: Hashable {
    typealias Visitor = Kosaraju<Graph>.Visitor
    
    func stronglyConnectedComponents(
        in graph: Graph,
        visitor: Visitor?
    ) -> StronglyConnectedComponentsResult<Graph.VertexDescriptor> {
        let kosaraju = Kosaraju(on: graph)
        return kosaraju.stronglyConnectedComponents(visitor: visitor)
    }
}

extension StronglyConnectedComponentsAlgorithm {
    static func kosaraju<Graph: BidirectionalGraph & VertexListGraph>() -> Self where Self == KosarajuStronglyConnectedComponentsAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}
