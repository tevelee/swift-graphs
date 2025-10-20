/// A protocol that defines the incidence structure of a graph.
///
/// An incidence graph provides access to the edges incident to each vertex and allows
/// traversal from vertices to their neighbors. This is one of the most fundamental
/// graph concepts, enabling most graph algorithms.
///
/// - Note: This protocol is inspired by the Boost Graph Library's incidence graph concept.
///   It provides the minimal interface needed for graph traversal and neighbor access.
public protocol IncidenceGraph<VertexDescriptor, EdgeDescriptor>: Graph {
    /// The type of sequence returned when querying outgoing edges.
    associatedtype OutgoingEdges: Sequence<EdgeDescriptor>

    /// Returns all outgoing edges from the specified vertex.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: A sequence of edge descriptors representing outgoing edges
    func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges
    
    /// Returns the source vertex of the specified edge.
    ///
    /// - Parameter edge: The edge to query
    /// - Returns: The source vertex, or `nil` if the edge is invalid
    func source(of edge: EdgeDescriptor) -> VertexDescriptor?
    
    /// Returns the destination vertex of the specified edge.
    ///
    /// - Parameter edge: The edge to query
    /// - Returns: The destination vertex, or `nil` if the edge is invalid
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor?
    
    /// Returns the number of outgoing edges from the specified vertex.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: The out-degree of the vertex
    func outDegree(of vertex: VertexDescriptor) -> Int
}

extension IncidenceGraph {
    /// Returns all successor vertices of the specified vertex.
    ///
    /// This is a convenience method that extracts the destination vertices from
    /// all outgoing edges of the given vertex.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: A lazy sequence of successor vertices
    @inlinable
    public func successors(of vertex: VertexDescriptor) -> some Sequence<VertexDescriptor> {
        outgoingEdges(of: vertex).lazy.compactMap(destination)
    }

    /// Determines whether the specified vertex is a sink (has no outgoing edges).
    ///
    /// - Parameter vertex: The vertex to check
    /// - Returns: `true` if the vertex has no outgoing edges, `false` otherwise
    @inlinable
    public func isSink(vertex: VertexDescriptor) -> Bool {
        outDegree(of: vertex) == 0
    }
}
