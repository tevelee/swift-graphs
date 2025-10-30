/// A protocol for graph isomorphism algorithms
public protocol IsomorphismAlgorithm<Graph> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & VertexListGraph & EdgeListGraph where Graph.VertexDescriptor: Hashable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Determines if two graphs are isomorphic.
    ///
    /// - Parameters:
    ///   - graph1: The first graph
    ///   - graph2: The second graph
    ///   - visitor: Optional visitor for algorithm events
    /// - Returns: `true` if the graphs are isomorphic, `false` otherwise
    @inlinable
    func areIsomorphic(_ graph1: Graph, _ graph2: Graph, visitor: Visitor?) -> Bool
    
    /// Finds an isomorphism mapping between two graphs.
    ///
    /// - Parameters:
    ///   - graph1: The first graph
    ///   - graph2: The second graph
    ///   - visitor: Optional visitor for algorithm events
    /// - Returns: A mapping from vertices of graph1 to vertices of graph2, or `nil` if not isomorphic
    @inlinable
    func findIsomorphism(_ graph1: Graph, _ graph2: Graph, visitor: Visitor?) -> [Graph.VertexDescriptor: Graph.VertexDescriptor]?
}

extension VisitorWrapper: IsomorphismAlgorithm where Base: IsomorphismAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    
    @inlinable
    public func areIsomorphic(_ graph1: Base.Graph, _ graph2: Base.Graph, visitor: Base.Visitor?) -> Bool {
        base.areIsomorphic(graph1, graph2, visitor: self.visitor.combined(with: visitor))
    }
    
    @inlinable
    public func findIsomorphism(_ graph1: Base.Graph, _ graph2: Base.Graph, visitor: Base.Visitor?) -> [Base.Graph.VertexDescriptor: Base.Graph.VertexDescriptor]? {
        base.findIsomorphism(graph1, graph2, visitor: self.visitor.combined(with: visitor))
    }
}

/// Result of an isomorphism check
public struct IsomorphismResult<Vertex: Hashable> {
    /// Whether the graphs are isomorphic.
    public let isIsomorphic: Bool
    /// The isomorphism mapping, if one exists.
    public let mapping: [Vertex: Vertex]?
    
    /// Creates a new isomorphism result.
    ///
    /// - Parameters:
    ///   - isIsomorphic: Whether the graphs are isomorphic
    ///   - mapping: The isomorphism mapping, if one exists
    @inlinable
    public init(isIsomorphic: Bool, mapping: [Vertex: Vertex]? = nil) {
        self.isIsomorphic = isIsomorphic
        self.mapping = mapping
    }
}

extension IsomorphismResult: Sendable where Vertex: Sendable {}

/// Extension to add isomorphism checking to graphs
extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    /// Checks if this graph is isomorphic to another graph.
    ///
    /// - Parameters:
    ///   - other: The graph to compare against
    ///   - using: The isomorphism algorithm to use
    /// - Returns: `true` if the graphs are isomorphic, `false` otherwise
    @inlinable
    public func isIsomorphic<Algorithm: IsomorphismAlgorithm<Self>>(
        to other: Self,
        using algorithm: Algorithm
    ) -> Bool {
        algorithm.areIsomorphic(self, other, visitor: nil)
    }
    
    /// Finds an isomorphism mapping to another graph.
    ///
    /// - Parameters:
    ///   - other: The graph to compare against
    ///   - using: The isomorphism algorithm to use
    /// - Returns: A mapping from vertices of this graph to vertices of the other graph, or `nil` if not isomorphic
    @inlinable
    public func findIsomorphism<Algorithm: IsomorphismAlgorithm<Self>>(
        to other: Self,
        using algorithm: Algorithm
    ) -> [VertexDescriptor: VertexDescriptor]? {
        algorithm.findIsomorphism(self, other, visitor: nil)
    }
    
    /// Checks isomorphism and returns detailed result.
    ///
    /// - Parameters:
    ///   - other: The graph to compare against
    ///   - using: The isomorphism algorithm to use
    /// - Returns: An `IsomorphismResult` containing the isomorphism status and mapping
    @inlinable
    public func isomorphismResult<Algorithm: IsomorphismAlgorithm<Self>>(
        with other: Self,
        using algorithm: Algorithm
    ) -> IsomorphismResult<VertexDescriptor> {
        let mapping = algorithm.findIsomorphism(self, other, visitor: nil)
        return IsomorphismResult(isIsomorphic: mapping != nil, mapping: mapping)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    /// Checks if this graph is isomorphic to another graph using VF2 algorithm as the default.
    /// VF2 is a well-known and efficient algorithm for graph isomorphism.
    ///
    /// - Parameter other: The graph to compare against
    /// - Returns: `true` if the graphs are isomorphic, `false` otherwise
    @inlinable
    public func isIsomorphic(to other: Self) -> Bool {
        isIsomorphic(to: other, using: .vf2())
    }
    
    /// Finds an isomorphism mapping to another graph using VF2 algorithm as the default.
    ///
    /// - Parameter other: The graph to compare against
    /// - Returns: A mapping from vertices of this graph to vertices of the other graph, or `nil` if not isomorphic
    @inlinable
    public func findIsomorphism(to other: Self) -> [VertexDescriptor: VertexDescriptor]? {
        findIsomorphism(to: other, using: .vf2())
    }
    
    /// Checks isomorphism and returns detailed result using VF2 algorithm as the default.
    ///
    /// - Parameter other: The graph to compare against
    /// - Returns: An `IsomorphismResult` containing the isomorphism status and mapping
    @inlinable
    public func isomorphismResult(with other: Self) -> IsomorphismResult<VertexDescriptor> {
        isomorphismResult(with: other, using: .vf2())
    }
}

