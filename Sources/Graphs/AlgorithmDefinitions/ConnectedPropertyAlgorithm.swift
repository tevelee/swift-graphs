import Foundation

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func isConnected(
        using algorithm: some ConnectedPropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.isConnected(in: self, visitor: nil)
    }
}

protocol ConnectedPropertyAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    associatedtype Visitor
    
    func isConnected(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool
}

extension VisitorWrapper: ConnectedPropertyAlgorithm where Base: ConnectedPropertyAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    func isConnected(in graph: Base.Graph, visitor: Base.Visitor?) -> Bool {
        base.isConnected(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
