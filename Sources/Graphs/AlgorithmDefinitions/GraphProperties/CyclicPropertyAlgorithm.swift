import Foundation

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is cyclic using the specified algorithm.
    ///
    /// - Parameter algorithm: The cyclic property algorithm to use
    /// - Returns: `true` if the graph is cyclic, `false` otherwise
    @inlinable
    public func isCyclic(
        using algorithm: some CyclicPropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.isCyclic(in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is cyclic using DFS-based algorithm as the default.
    /// This is the most commonly used and efficient algorithm for cycle detection.
    ///
    /// - Returns: `true` if the graph is cyclic, `false` otherwise
    @inlinable
    public func isCyclic() -> Bool {
        isCyclic(using: .dfs())
    }
}

/// A protocol for cyclic property algorithms.
public protocol CyclicPropertyAlgorithm<Graph> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Checks if the graph is cyclic.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: `true` if the graph is cyclic, `false` otherwise
    @inlinable
    func isCyclic(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool
}

extension VisitorWrapper: CyclicPropertyAlgorithm where Base: CyclicPropertyAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    
    @inlinable
    public func isCyclic(in graph: Base.Graph, visitor: Base.Visitor?) -> Bool {
        base.isCyclic(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
