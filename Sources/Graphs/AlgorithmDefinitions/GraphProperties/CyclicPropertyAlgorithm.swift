import Foundation

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func isCyclic(
        using algorithm: some CyclicPropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.isCyclic(in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is cyclic using DFS-based algorithm as the default.
    /// This is the most commonly used and efficient algorithm for cycle detection.
    func isCyclic() -> Bool {
        isCyclic(using: .dfs())
    }
}

protocol CyclicPropertyAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    associatedtype Visitor
    
    func isCyclic(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool
}

extension VisitorWrapper: CyclicPropertyAlgorithm where Base: CyclicPropertyAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    func isCyclic(in graph: Base.Graph, visitor: Base.Visitor?) -> Bool {
        base.isCyclic(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
