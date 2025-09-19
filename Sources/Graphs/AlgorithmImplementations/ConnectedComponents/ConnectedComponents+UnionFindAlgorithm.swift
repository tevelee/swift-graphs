struct UnionFindConnectedComponentsAlgorithm<Graph: IncidenceGraph & VertexListGraph>: ConnectedComponentsAlgorithm where Graph.VertexDescriptor: Hashable {
    typealias Visitor = UnionFindConnectedComponents<Graph>.Visitor
    
    func connectedComponents(
        in graph: Graph,
        visitor: Visitor?
    ) -> [[Graph.VertexDescriptor]] {
        let unionFind = UnionFindConnectedComponents(on: graph)
        return unionFind.connectedComponents(visitor: visitor)
    }
}

extension ConnectedComponentsAlgorithm {
    static func unionFind<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == UnionFindConnectedComponentsAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}
