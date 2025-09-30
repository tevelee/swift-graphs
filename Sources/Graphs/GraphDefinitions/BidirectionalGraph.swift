/// A protocol for graphs that provide access to both incoming and outgoing edges.
///
/// A bidirectional graph extends the incidence graph concept to support traversal
/// in both directions - from vertices to their successors (outgoing edges) and
/// from vertices to their predecessors (incoming edges). This is essential for
/// many graph algorithms that need to traverse edges in both directions.
public protocol BidirectionalGraph: IncidenceGraph {
    /// The type of sequence returned when querying incoming edges.
    associatedtype IncomingEdges: Sequence<EdgeDescriptor>

    /// Returns all incoming edges to the specified vertex.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: A sequence of edge descriptors representing incoming edges
    func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges
    
    /// Returns the number of incoming edges to the specified vertex.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: The in-degree of the vertex
    func inDegree(of vertex: VertexDescriptor) -> Int
    
    /// Returns the total degree (in-degree + out-degree) of the specified vertex.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: The total degree of the vertex
    func degree(of vertex: VertexDescriptor) -> Int
}

extension BidirectionalGraph {
    /// Returns all predecessor vertices of the specified vertex.
    ///
    /// This is a convenience method that extracts the source vertices from
    /// all incoming edges of the given vertex.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: A lazy sequence of predecessor vertices
    @inlinable
    public func predecessors(of vertex: VertexDescriptor) -> some Sequence<VertexDescriptor> {
        incomingEdges(of: vertex).lazy.compactMap(source)
    }

    /// Returns the total degree (in-degree + out-degree) of the specified vertex.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: The total degree of the vertex
    @inlinable
    public func degree(of vertex: VertexDescriptor) -> Int {
        inDegree(of: vertex) + outDegree(of: vertex)
    }
    
    /// Determines whether the specified vertex is isolated (has no edges).
    ///
    /// - Parameter vertex: The vertex to check
    /// - Returns: `true` if the vertex has no edges, `false` otherwise
    @inlinable
    public func isIsolated(vertex: VertexDescriptor) -> Bool {
        degree(of: vertex) == 0
    }

    /// Determines whether the specified vertex is a source (has no incoming edges).
    ///
    /// - Parameter vertex: The vertex to check
    /// - Returns: `true` if the vertex has no incoming edges, `false` otherwise
    @inlinable
    public func isSource(vertex: VertexDescriptor) -> Bool {
        inDegree(of: vertex) == 0
    }

    /// Determines whether the specified vertex is a leaf (has degree 1).
    ///
    /// - Parameter vertex: The vertex to check
    /// - Returns: `true` if the vertex has exactly one edge, `false` otherwise
    @inlinable
    public func isLeaf(vertex: VertexDescriptor) -> Bool {
        degree(of: vertex) == 1
    }
}
