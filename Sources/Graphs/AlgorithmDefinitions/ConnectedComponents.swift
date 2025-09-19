extension IncidenceGraph where VertexDescriptor: Hashable {
    func connectedComponents(
        using algorithm: some ConnectedComponentsAlgorithm<Self>
    ) -> [[VertexDescriptor]] {
        algorithm.connectedComponents(in: self, visitor: nil)
    }
}

protocol ConnectedComponentsAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph
    associatedtype Visitor

    func connectedComponents(
        in graph: Graph,
        visitor: Visitor?
    ) -> [[Graph.VertexDescriptor]]
}

extension VisitorWrapper: ConnectedComponentsAlgorithm where Base: ConnectedComponentsAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    typealias Graph = Base.Graph
    
    func connectedComponents(
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> [[Base.Graph.VertexDescriptor]] {
        base.connectedComponents(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
