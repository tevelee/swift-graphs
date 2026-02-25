/// A protocol for vertex ordering algorithms.
public protocol VertexOrderingAlgorithm<Graph> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph where Graph.VertexDescriptor: Hashable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Orders the vertices of a graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to order vertices for
    ///   - visitor: Optional visitor for algorithm events
    /// - Returns: An array of vertex descriptors in the computed order
    func orderVertices(in graph: Graph, visitor: Visitor?) -> [Graph.VertexDescriptor]
}

extension VisitorWrapper: VertexOrderingAlgorithm where Base: VertexOrderingAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    
    @inlinable
    public func orderVertices(in graph: Base.Graph, visitor: Base.Visitor?) -> [Base.Graph.VertexDescriptor] {
        base.orderVertices(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

/// Result of a vertex ordering algorithm.
public struct VertexOrdering<Vertex: Hashable> {
    /// The vertices in the computed order.
    public let orderedVertices: [Vertex]
    
    /// The position of each vertex in the ordering (0-based index).
    public let vertexPositions: [Vertex: Int]
    
    /// Creates a new vertex ordering result.
    ///
    /// - Parameter orderedVertices: The vertices in the computed order
    @inlinable
    public init(orderedVertices: [Vertex]) {
        self.orderedVertices = orderedVertices
        self.vertexPositions = Dictionary(uniqueKeysWithValues: orderedVertices.enumerated().map { ($0.element, $0.offset) })
    }
    
    /// Get the position of a vertex in the ordering.
    ///
    /// - Parameter vertex: The vertex to look up
    /// - Returns: The 0-based position of the vertex, or nil if not found
    @inlinable
    public func position(of vertex: Vertex) -> Int? {
        vertexPositions[vertex]
    }
    
    /// Get the vertex at a specific position.
    ///
    /// - Parameter position: The 0-based position
    /// - Returns: The vertex at that position, or nil if out of bounds
    @inlinable
    public func vertex(at position: Int) -> Vertex? {
        guard position >= 0 && position < orderedVertices.count else { return nil }
        return orderedVertices[position]
    }
}

/// Extension to add ordering capabilities to graphs
extension IncidenceGraph where Self: VertexListGraph & BidirectionalGraph, VertexDescriptor: Hashable {
    /// Order the vertices of this graph using the specified algorithm.
    ///
    /// - Parameter algorithm: The ordering algorithm to use
    /// - Returns: A vertex ordering containing the ordered vertices
    @inlinable
    public func orderVertices<Algorithm: VertexOrderingAlgorithm>(
        using algorithm: Algorithm
    ) -> VertexOrdering<VertexDescriptor> where Algorithm.Graph == Self {
        let orderedVertices = algorithm.orderVertices(in: self, visitor: nil)
        return VertexOrdering(orderedVertices: orderedVertices)
    }
}

// MARK: - Default Implementations

#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
extension IncidenceGraph where Self: VertexListGraph & BidirectionalGraph, VertexDescriptor: Hashable {
    /// Orders vertices using Smallest Last Vertex Ordering as the default.
    /// This is particularly effective for graph coloring algorithms.
    ///
    /// - Returns: A vertex ordering containing the ordered vertices
    @inlinable
    public func orderVertices() -> VertexOrdering<VertexDescriptor> {
        orderVertices(using: .smallestLastVertex())
    }

    /// Orders vertices using Reverse Cuthill-McKee algorithm for bandwidth reduction.
    /// This is particularly effective for reducing matrix bandwidth.
    ///
    /// - Returns: A vertex ordering containing the ordered vertices
    @inlinable
    public func orderVerticesForBandwidthReduction() -> VertexOrdering<VertexDescriptor> {
        orderVertices(using: .reverseCuthillMcKee())
    }
}
#endif
