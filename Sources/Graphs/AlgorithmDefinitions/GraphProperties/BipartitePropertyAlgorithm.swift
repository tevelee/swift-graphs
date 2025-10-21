extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is bipartite using the specified algorithm.
    ///
    /// - Parameter algorithm: The bipartite property algorithm to use
    /// - Returns: `true` if the graph is bipartite, `false` otherwise
    @inlinable
    public func isBipartite(
        using algorithm: some BipartitePropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.isBipartite(in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is bipartite using DFS-based algorithm as the default.
    /// This is the most commonly used and efficient algorithm for bipartiteness checking.
    ///
    /// - Returns: `true` if the graph is bipartite, `false` otherwise
    @inlinable
    public func isBipartite() -> Bool {
        isBipartite(using: .dfs())
    }
}

/// A protocol for bipartite property algorithms.
public protocol BipartitePropertyAlgorithm<Graph> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Checks if the graph is bipartite.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: `true` if the graph is bipartite, `false` otherwise
    @inlinable
    func isBipartite(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool
}

extension VisitorWrapper: BipartitePropertyAlgorithm where Base: BipartitePropertyAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    
    @inlinable
    public func isBipartite(in graph: Base.Graph, visitor: Base.Visitor?) -> Bool {
        base.isBipartite(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
