import Foundation

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func isBipartite(
        using algorithm: some BipartitePropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.isBipartite(in: self, visitor: nil)
    }
}

protocol BipartitePropertyAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    associatedtype Visitor
    
    func isBipartite(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool
}

extension VisitorWrapper: BipartitePropertyAlgorithm where Base: BipartitePropertyAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    func isBipartite(in graph: Base.Graph, visitor: Base.Visitor?) -> Bool {
        base.isBipartite(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
