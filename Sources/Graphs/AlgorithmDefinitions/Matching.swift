/// A protocol for maximum matching algorithms on bipartite graphs.
public protocol MatchingAlgorithm<Graph> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: BipartiteGraph & IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Finds the maximum matching in the bipartite graph.
    ///
    /// - Parameters:
    ///   - graph: The bipartite graph to find matching in
    ///   - visitor: Optional visitor for algorithm events
    /// - Returns: The maximum matching result
    func maximumMatching(in graph: Graph, visitor: Visitor?) -> MatchingResult<Graph.VertexDescriptor, Graph.EdgeDescriptor>
}

/// Result of a maximum matching computation.
public struct MatchingResult<Vertex: Hashable, Edge> {
    /// The maximum matching size (number of matched vertices).
    public let matchingSize: Int
    
    /// The edges in the maximum matching.
    public let matchingEdges: [Edge]
    
    /// The vertices that are matched (covered by the matching).
    public let matchedVertices: Set<Vertex>
    
    /// The vertices that are unmatched (not covered by the matching).
    public let unmatchedVertices: Set<Vertex>
    
    /// The left partition vertices that are matched.
    public let matchedLeftVertices: Set<Vertex>
    
    /// The right partition vertices that are matched.
    public let matchedRightVertices: Set<Vertex>
    
    /// The left partition vertices that are unmatched.
    public let unmatchedLeftVertices: Set<Vertex>
    
    /// The right partition vertices that are unmatched.
    public let unmatchedRightVertices: Set<Vertex>
    
    /// Internal mapping from vertex to its matching partner.
    /// This is used to efficiently look up partners without needing graph access.
    @usableFromInline
    let partnerMap: [Vertex: Vertex]
    
    /// Creates a new matching result.
    ///
    /// - Parameters:
    ///   - matchingSize: The maximum matching size
    ///   - matchingEdges: The edges in the maximum matching
    ///   - matchedVertices: The vertices that are matched
    ///   - unmatchedVertices: The vertices that are unmatched
    ///   - matchedLeftVertices: The left partition vertices that are matched
    ///   - matchedRightVertices: The right partition vertices that are matched
    ///   - unmatchedLeftVertices: The left partition vertices that are unmatched
    ///   - unmatchedRightVertices: The right partition vertices that are unmatched
    ///   - partnerMap: Optional mapping from vertex to its matching partner. If nil, will be computed from matchingEdges when possible.
    @inlinable
    public init(
        matchingSize: Int,
        matchingEdges: [Edge],
        matchedVertices: Set<Vertex>,
        unmatchedVertices: Set<Vertex>,
        matchedLeftVertices: Set<Vertex>,
        matchedRightVertices: Set<Vertex>,
        unmatchedLeftVertices: Set<Vertex>,
        unmatchedRightVertices: Set<Vertex>,
        partnerMap: [Vertex: Vertex]? = nil
    ) {
        self.matchingSize = matchingSize
        self.matchingEdges = matchingEdges
        self.matchedVertices = matchedVertices
        self.unmatchedVertices = unmatchedVertices
        self.matchedLeftVertices = matchedLeftVertices
        self.matchedRightVertices = matchedRightVertices
        self.unmatchedLeftVertices = unmatchedLeftVertices
        self.unmatchedRightVertices = unmatchedRightVertices
        
        // Use provided partner map, or build empty map if not provided
        // Algorithms should provide the partner map for efficient lookup
        self.partnerMap = partnerMap ?? [:]
    }
    
    /// Check if a vertex is matched.
    ///
    /// - Parameter vertex: The vertex to check
    /// - Returns: True if the vertex is matched
    @inlinable
    public func isMatched(_ vertex: Vertex) -> Bool {
        matchedVertices.contains(vertex)
    }
    
    /// Check if a vertex is unmatched.
    ///
    /// - Parameter vertex: The vertex to check
    /// - Returns: True if the vertex is unmatched
    @inlinable
    public func isUnmatched(_ vertex: Vertex) -> Bool {
        unmatchedVertices.contains(vertex)
    }
    
    /// Get the matching partner of a vertex.
    ///
    /// - Parameter vertex: The vertex to get the partner for
    /// - Returns: The matching partner, or nil if the vertex is unmatched
    @inlinable
    public func partner(of vertex: Vertex) -> Vertex? {
        guard isMatched(vertex) else { return nil }
        return partnerMap[vertex]
    }
}

extension MatchingResult: Sendable where Vertex: Sendable, Edge: Sendable {}

extension VisitorWrapper: MatchingAlgorithm where Base: MatchingAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    
    @inlinable
    public func maximumMatching(in graph: Base.Graph, visitor: Base.Visitor?) -> MatchingResult<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor> {
        base.maximumMatching(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

extension BipartiteGraph where Self: IncidenceGraph & VertexListGraph {
    /// Finds the maximum matching using the specified algorithm.
    ///
    /// - Parameters:
    ///   - algorithm: The matching algorithm to use
    /// - Returns: The maximum matching result
    @inlinable
    public func maximumMatching(using algorithm: some MatchingAlgorithm<Self>) -> MatchingResult<VertexDescriptor, EdgeDescriptor> {
        algorithm.maximumMatching(in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension BipartiteGraph where Self: IncidenceGraph & VertexListGraph {
    /// Finds the maximum matching using Hopcroft-Karp algorithm as the default.
    /// This is the most efficient algorithm for maximum matching in bipartite graphs.
    ///
    /// - Returns: The maximum matching result
    @inlinable
    public func maximumMatching() -> MatchingResult<VertexDescriptor, EdgeDescriptor> {
        maximumMatching(using: .hopcroftKarp())
    }
}
