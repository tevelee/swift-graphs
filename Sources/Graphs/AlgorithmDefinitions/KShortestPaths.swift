/// A protocol for algorithms that find k shortest paths.
public protocol KShortestPathsAlgorithm<Graph, Weight> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph
    /// The weight type for edge costs.
    associatedtype Weight: AdditiveArithmetic & Comparable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Finds the k shortest paths from source to destination.
    ///
    /// - Parameters:
    ///   - source: The source vertex
    ///   - destination: The destination vertex
    ///   - k: The number of shortest paths to find
    ///   - graph: The graph to search in
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: An array of the k shortest paths, ordered by cost
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

// MARK: - Default Implementations

extension IncidenceGraph where Self: EdgePropertyGraph, VertexDescriptor: Hashable, EdgeDescriptor: Hashable {
    /// Finds the k shortest paths using Yen's algorithm as the default.
    /// This is the most commonly used algorithm for finding k shortest paths.
    func kShortestPaths<Weight: Numeric & Comparable>(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        k: Int,
        weight: CostDefinition<Self, Weight>
    ) -> [Path<VertexDescriptor, EdgeDescriptor>] where Weight.Magnitude == Weight {
        kShortestPaths(from: source, to: destination, k: k, using: .yen(weight: weight))
    }
}

extension VisitorWrapper: KShortestPathsAlgorithm where Base: KShortestPathsAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    public typealias Weight = Base.Weight
    
    @inlinable
    public func kShortestPaths(
        from source: Base.Graph.VertexDescriptor,
        to destination: Base.Graph.VertexDescriptor,
        k: Int,
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> [Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>] {
        base.kShortestPaths(from: source, to: destination, k: k, in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
