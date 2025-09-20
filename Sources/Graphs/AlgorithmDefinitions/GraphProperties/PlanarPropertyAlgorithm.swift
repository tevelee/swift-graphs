import Foundation

extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    func isPlanar(
        using algorithm: some PlanarPropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.isPlanar(in: self, visitor: nil)
    }
}

protocol PlanarPropertyAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph & EdgeListGraph where Graph.VertexDescriptor: Hashable
    associatedtype Visitor
    
    func isPlanar(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool
}

extension VisitorWrapper: PlanarPropertyAlgorithm where Base: PlanarPropertyAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    func isPlanar(in graph: Base.Graph, visitor: Base.Visitor?) -> Bool {
        base.isPlanar(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
