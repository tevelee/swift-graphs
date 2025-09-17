import Foundation

/// A protocol for graph isomorphism algorithms
protocol IsomorphismAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph & VertexListGraph & EdgeListGraph where Graph.VertexDescriptor: Hashable
    
    /// Determines if two graphs are isomorphic
    /// - Parameters:
    ///   - graph1: The first graph
    ///   - graph2: The second graph
    /// - Returns: `true` if the graphs are isomorphic, `false` otherwise
    func areIsomorphic(_ graph1: Graph, _ graph2: Graph) -> Bool
    
    /// Finds an isomorphism mapping between two graphs
    /// - Parameters:
    ///   - graph1: The first graph
    ///   - graph2: The second graph
    /// - Returns: A mapping from vertices of graph1 to vertices of graph2, or `nil` if not isomorphic
    func findIsomorphism(_ graph1: Graph, _ graph2: Graph) -> [Graph.VertexDescriptor: Graph.VertexDescriptor]?
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
        algorithm.areIsomorphic(self, other)
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
        algorithm.findIsomorphism(self, other)
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
        let mapping = algorithm.findIsomorphism(self, other)
        return IsomorphismResult(isIsomorphic: mapping != nil, mapping: mapping)
    }
}

