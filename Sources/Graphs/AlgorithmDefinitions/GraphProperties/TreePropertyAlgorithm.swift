import Foundation

extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    func isTree(
        using algorithm: some TreePropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.isTree(in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is a tree using DFS-based algorithm as the default.
    /// A graph is a tree if it's connected and has no cycles.
    func isTree() -> Bool {
        isTree(using: .dfs())
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
