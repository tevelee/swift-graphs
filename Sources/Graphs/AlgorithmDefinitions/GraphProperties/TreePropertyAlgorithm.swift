extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is a tree using the specified algorithm.
    ///
    /// - Parameter algorithm: The tree property algorithm to use
    /// - Returns: `true` if the graph is a tree, `false` otherwise
    @inlinable
    public func isTree(
        using algorithm: some TreePropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.isTree(in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is a tree using DFS-based algorithm as the default.
    /// A graph is a tree if it's connected and has no cycles.
    ///
    /// - Returns: `true` if the graph is a tree, `false` otherwise
    @inlinable
    public func isTree() -> Bool {
        isTree(using: .dfs())
    }
}

/// A protocol for tree property algorithms.
public protocol TreePropertyAlgorithm<Graph> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & EdgeListGraph where Graph.VertexDescriptor: Hashable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Checks if the graph is a tree.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: `true` if the graph is a tree, `false` otherwise
    @inlinable
    func isTree(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool
}

extension VisitorWrapper: TreePropertyAlgorithm where Base: TreePropertyAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    
    @inlinable
    public func isTree(in graph: Base.Graph, visitor: Base.Visitor?) -> Bool {
        base.isTree(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
