extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func stronglyConnectedComponents(
        using algorithm: some StronglyConnectedComponentsAlgorithm<Self>
    ) -> [[VertexDescriptor]] {
        algorithm.stronglyConnectedComponents(in: self, visitor: nil)
    }
}

extension BidirectionalGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func stronglyConnectedComponents(
        using algorithm: some StronglyConnectedComponentsAlgorithm<Self>
    ) -> [[VertexDescriptor]] {
        algorithm.stronglyConnectedComponents(in: self, visitor: nil)
    }
}

protocol StronglyConnectedComponentsAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph
    associatedtype Visitor

    func stronglyConnectedComponents(
        in graph: Graph,
        visitor: Visitor?
    ) -> [[Graph.VertexDescriptor]]
}

extension VisitorWrapper: StronglyConnectedComponentsAlgorithm where Base: StronglyConnectedComponentsAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    typealias Graph = Base.Graph
    
    func stronglyConnectedComponents(
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> [[Base.Graph.VertexDescriptor]] {
        base.stronglyConnectedComponents(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
