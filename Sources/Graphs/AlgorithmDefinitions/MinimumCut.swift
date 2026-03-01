/// A protocol for global minimum cut algorithms.
///
/// A global minimum cut partitions the vertices of an undirected weighted graph into two non-empty sets
/// such that the total weight of edges crossing the partition is minimized — without specifying source or sink vertices.
///
/// - Note: For directed graphs, apply the `.undirected()` view first.
public protocol MinimumCutAlgorithm<Graph, Weight> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable, Graph.EdgeDescriptor: Hashable
    /// The weight type for edge costs.
    associatedtype Weight: Numeric & Comparable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor

    /// Computes the global minimum cut of the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to find the minimum cut for
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: The minimum cut result, or `nil` if the graph has fewer than 2 vertices
    func minimumCut(in graph: Graph, visitor: Visitor?) -> MinimumCutResult<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight>?
}

/// Represents the result of a global minimum cut computation.
public struct MinimumCutResult<Vertex: Hashable, Edge: Hashable, Weight: Numeric & Comparable> {
    /// The total weight of the cut (sum of edge weights crossing the partition).
    public let cutWeight: Weight

    /// The first partition of vertices.
    public let partitionA: Set<Vertex>

    /// The second partition of vertices.
    public let partitionB: Set<Vertex>

    /// The edges crossing the cut.
    public let cutEdges: [Edge]

    /// A set of cut edges for efficient O(1) lookup.
    @usableFromInline
    let cutEdgeSet: Set<Edge>

    /// Creates a new minimum cut result.
    ///
    /// - Parameters:
    ///   - cutWeight: The total weight of the cut
    ///   - partitionA: The first partition of vertices
    ///   - partitionB: The second partition of vertices
    ///   - cutEdges: The edges crossing the cut
    @inlinable
    public init(cutWeight: Weight, partitionA: Set<Vertex>, partitionB: Set<Vertex>, cutEdges: [Edge]) {
        self.cutWeight = cutWeight
        self.partitionA = partitionA
        self.partitionB = partitionB
        self.cutEdges = cutEdges
        self.cutEdgeSet = Set(cutEdges)
    }

    /// Returns whether the given edge is a cut edge.
    ///
    /// - Parameter edge: The edge to check
    /// - Returns: True if the edge crosses the cut
    @inlinable
    public func isCutEdge(_ edge: Edge) -> Bool {
        cutEdgeSet.contains(edge)
    }
}

extension MinimumCutResult: Sendable where Vertex: Sendable, Edge: Sendable, Weight: Sendable {}

extension MinimumCutResult: Equatable where Vertex: Equatable, Edge: Equatable, Weight: Equatable {
    public static func == (lhs: MinimumCutResult, rhs: MinimumCutResult) -> Bool {
        lhs.cutWeight == rhs.cutWeight && lhs.partitionA == rhs.partitionA && lhs.partitionB == rhs.partitionB && lhs.cutEdgeSet == rhs.cutEdgeSet
    }
}

extension VisitorWrapper: MinimumCutAlgorithm where Base: MinimumCutAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    public typealias Weight = Base.Weight

    @inlinable
    public func minimumCut(in graph: Base.Graph, visitor: Base.Visitor?) -> MinimumCutResult<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor, Base.Weight>? {
        base.minimumCut(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

extension IncidenceGraph {
    /// Computes the global minimum cut using the specified algorithm.
    ///
    /// - Parameter algorithm: The minimum cut algorithm to use
    /// - Returns: The minimum cut result, or `nil` if the graph has fewer than 2 vertices
    @inlinable
    public func minimumCut<Weight: Numeric & Comparable>(
        using algorithm: some MinimumCutAlgorithm<Self, Weight>
    ) -> MinimumCutResult<VertexDescriptor, EdgeDescriptor, Weight>? {
        algorithm.minimumCut(in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
extension IncidenceGraph where Self: EdgeListGraph & VertexListGraph, VertexDescriptor: Hashable, EdgeDescriptor: Hashable {
    /// Finds the global minimum cut using Stoer-Wagner's algorithm as the default.
    ///
    /// - Parameter weight: The cost definition for edge weights
    /// - Returns: The minimum cut result, or `nil` if the graph has fewer than 2 vertices
    @inlinable
    public func minimumCut<Weight: Numeric & Comparable>(
        weight: CostDefinition<Self, Weight>
    ) -> MinimumCutResult<VertexDescriptor, EdgeDescriptor, Weight>? {
        minimumCut(using: .stoerWagner(weight: weight))
    }
}
#endif
