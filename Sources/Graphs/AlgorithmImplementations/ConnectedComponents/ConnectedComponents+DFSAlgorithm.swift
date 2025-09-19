struct DFSConnectedComponentsAlgorithm<Graph: IncidenceGraph & VertexListGraph>: ConnectedComponentsAlgorithm where Graph.VertexDescriptor: Hashable {
    typealias Visitor = DFSConnectedComponents<Graph>.Visitor
    
    func connectedComponents(
        in graph: Graph,
        visitor: Visitor?
    ) -> ConnectedComponentsResult<Graph.VertexDescriptor> {
        let dfs = DFSConnectedComponents(on: graph)
        return dfs.connectedComponents(visitor: visitor)
    }
}

extension ConnectedComponentsAlgorithm {
    static func dfs<Graph: IncidenceGraph & VertexListGraph>() -> Self where Self == DFSConnectedComponentsAlgorithm<Graph>, Graph.VertexDescriptor: Hashable {
        .init()
    }
}
