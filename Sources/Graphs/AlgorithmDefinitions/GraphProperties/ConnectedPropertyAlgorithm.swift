extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is connected using the specified algorithm.
    ///
    /// - Parameter algorithm: The connected property algorithm to use
    /// - Returns: `true` if the graph is connected, `false` otherwise
    @inlinable
    public func isConnected(
        using algorithm: some ConnectedPropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.isConnected(in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is connected using DFS-based algorithm as the default.
    /// This is the most commonly used and efficient algorithm for connectivity checking.
    ///
    /// - Returns: `true` if the graph is connected, `false` otherwise
    @inlinable
    public func isConnected() -> Bool {
        isConnected(using: .dfs())
    }
}

/// A protocol for connected property algorithms.
public protocol ConnectedPropertyAlgorithm<Graph> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Checks if the graph is connected.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: `true` if the graph is connected, `false` otherwise
    @inlinable
    func isConnected(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool
}

extension VisitorWrapper: ConnectedPropertyAlgorithm where Base: ConnectedPropertyAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    
    @inlinable
    public func isConnected(in graph: Base.Graph, visitor: Base.Visitor?) -> Bool {
        base.isConnected(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
