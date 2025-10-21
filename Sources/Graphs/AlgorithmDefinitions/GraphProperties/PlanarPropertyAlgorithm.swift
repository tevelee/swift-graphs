extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is planar using the specified algorithm.
    ///
    /// - Parameter algorithm: The planar property algorithm to use
    /// - Returns: `true` if the graph is planar, `false` otherwise
    @inlinable
    public func isPlanar(
        using algorithm: some PlanarPropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.isPlanar(in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    /// Checks if the graph is planar using Boyer-Myrvold algorithm as the default.
    /// This is a well-known and efficient algorithm for planarity testing.
    ///
    /// - Returns: `true` if the graph is planar, `false` otherwise
    @inlinable
    public func isPlanar() -> Bool {
        isPlanar(using: .boyerMyrvold())
    }
}

/// A protocol for planar property algorithms.
public protocol PlanarPropertyAlgorithm<Graph> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & EdgeListGraph where Graph.VertexDescriptor: Hashable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Checks if the graph is planar.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: `true` if the graph is planar, `false` otherwise
    @inlinable
    func isPlanar(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool
}

extension VisitorWrapper: PlanarPropertyAlgorithm where Base: PlanarPropertyAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    
    @inlinable
    public func isPlanar(in graph: Base.Graph, visitor: Base.Visitor?) -> Bool {
        base.isPlanar(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
