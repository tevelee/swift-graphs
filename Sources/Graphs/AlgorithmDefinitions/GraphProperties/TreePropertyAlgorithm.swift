import Foundation

extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    func isTree(
        using algorithm: some TreePropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.isTree(in: self, visitor: nil)
    }
}

protocol TreePropertyAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph & EdgeListGraph where Graph.VertexDescriptor: Hashable
    associatedtype Visitor
    
    func isTree(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool
}

extension VisitorWrapper: TreePropertyAlgorithm where Base: TreePropertyAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    func isTree(in graph: Base.Graph, visitor: Base.Visitor?) -> Bool {
        base.isTree(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
