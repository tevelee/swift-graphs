import Foundation

/// A protocol for graph isomorphism algorithms
protocol IsomorphismAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph & VertexListGraph & EdgeListGraph where Graph.VertexDescriptor: Hashable
    associatedtype Visitor
    
    /// Determines if two graphs are isomorphic
    /// - Parameters:
    ///   - graph1: The first graph
    ///   - graph2: The second graph
    ///   - visitor: Optional visitor for algorithm events
    /// - Returns: `true` if the graphs are isomorphic, `false` otherwise
    func areIsomorphic(_ graph1: Graph, _ graph2: Graph, visitor: Visitor?) -> Bool
    
    /// Finds an isomorphism mapping between two graphs
    /// - Parameters:
    ///   - graph1: The first graph
    ///   - graph2: The second graph
    ///   - visitor: Optional visitor for algorithm events
    /// - Returns: A mapping from vertices of graph1 to vertices of graph2, or `nil` if not isomorphic
    func findIsomorphism(_ graph1: Graph, _ graph2: Graph, visitor: Visitor?) -> [Graph.VertexDescriptor: Graph.VertexDescriptor]?
}

extension VisitorWrapper: IsomorphismAlgorithm where Base: IsomorphismAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    typealias Graph = Base.Graph
    
    func areIsomorphic(_ graph1: Base.Graph, _ graph2: Base.Graph, visitor: Base.Visitor?) -> Bool {
        base.areIsomorphic(graph1, graph2, visitor: self.visitor.combined(with: visitor))
    }
    
    func findIsomorphism(_ graph1: Base.Graph, _ graph2: Base.Graph, visitor: Base.Visitor?) -> [Base.Graph.VertexDescriptor: Base.Graph.VertexDescriptor]? {
        base.findIsomorphism(graph1, graph2, visitor: self.visitor.combined(with: visitor))
    }
}

/// Result of an isomorphism check
struct IsomorphismResult<Vertex: Hashable> {
    let isIsomorphic: Bool
    let mapping: [Vertex: Vertex]?
    
    init(isIsomorphic: Bool, mapping: [Vertex: Vertex]? = nil) {
        self.isIsomorphic = isIsomorphic
        self.mapping = mapping
    }
}

/// Extension to add isomorphism checking to graphs
extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    /// Checks if this graph is isomorphic to another graph
    /// - Parameters:
    ///   - other: The graph to compare against
    ///   - using: The isomorphism algorithm to use
    /// - Returns: `true` if the graphs are isomorphic, `false` otherwise
    func isIsomorphic<Algorithm: IsomorphismAlgorithm<Self>>(
        to other: Self,
        using algorithm: Algorithm
    ) -> Bool {
        algorithm.areIsomorphic(self, other, visitor: nil)
    }
    
    /// Finds an isomorphism mapping to another graph
    /// - Parameters:
    ///   - other: The graph to compare against
    ///   - using: The isomorphism algorithm to use
    /// - Returns: A mapping from vertices of this graph to vertices of the other graph, or `nil` if not isomorphic
    func findIsomorphism<Algorithm: IsomorphismAlgorithm<Self>>(
        to other: Self,
        using algorithm: Algorithm
    ) -> [VertexDescriptor: VertexDescriptor]? {
        algorithm.findIsomorphism(self, other, visitor: nil)
    }
    
    /// Checks isomorphism and returns detailed result
    /// - Parameters:
    ///   - other: The graph to compare against
    ///   - using: The isomorphism algorithm to use
    /// - Returns: An `IsomorphismResult` containing the isomorphism status and mapping
    func isomorphismResult<Algorithm: IsomorphismAlgorithm<Self>>(
        with other: Self,
        using algorithm: Algorithm
    ) -> IsomorphismResult<VertexDescriptor> {
        let mapping = algorithm.findIsomorphism(self, other, visitor: nil)
        return IsomorphismResult(isIsomorphic: mapping != nil, mapping: mapping)
    }
}

