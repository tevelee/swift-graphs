import Foundation

protocol KShortestPathsAlgorithm<Graph, Weight> {
    associatedtype Graph: IncidenceGraph
    associatedtype Weight: AdditiveArithmetic & Comparable
    associatedtype Visitor
    
    func kShortestPaths(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        k: Int,
        in graph: Graph,
        visitor: Visitor?
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>]
}

extension IncidenceGraph where VertexDescriptor: Equatable {
    func kShortestPaths<Weight: AdditiveArithmetic & Comparable>(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        k: Int,
        using algorithm: some KShortestPathsAlgorithm<Self, Weight>
    ) -> [Path<VertexDescriptor, EdgeDescriptor>] {
        algorithm.kShortestPaths(from: source, to: destination, k: k, in: self, visitor: nil)
    }
}

extension VisitorWrapper: KShortestPathsAlgorithm where Base: KShortestPathsAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    typealias Graph = Base.Graph
    typealias Weight = Base.Weight
    
    func kShortestPaths(
        from source: Base.Graph.VertexDescriptor,
        to destination: Base.Graph.VertexDescriptor,
        k: Int,
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> [Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>] {
        base.kShortestPaths(from: source, to: destination, k: k, in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
