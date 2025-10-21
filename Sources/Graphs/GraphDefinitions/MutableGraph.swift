/// A protocol for graphs that support adding and removing vertices.
///
/// Vertex-mutable graphs allow dynamic modification of the vertex set,
/// enabling the construction and modification of graphs at runtime.
public protocol VertexMutableGraph: Graph {
    /// Adds a new vertex to the graph.
    ///
    /// - Returns: The descriptor of the newly added vertex
    mutating func addVertex() -> VertexDescriptor
    
    /// Removes a vertex from the graph.
    ///
    /// - Parameter vertex: The vertex to remove
    #if swift(>=6.2)
    mutating func remove(vertex: consuming VertexDescriptor)
    #else
    mutating func remove(vertex: VertexDescriptor)
    #endif
}

/// A protocol for graphs that support adding and removing edges.
///
/// Edge-mutable graphs allow dynamic modification of the edge set,
/// enabling the construction and modification of graph connectivity at runtime.
public protocol EdgeMutableGraph: Graph {
    /// Adds a new edge to the graph.
    ///
    /// - Parameters:
    ///   - source: The source vertex of the edge
    ///   - destination: The destination vertex of the edge
    /// - Returns: The descriptor of the newly added edge, or `nil` if the edge could not be added
    @discardableResult
    mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor?
    
    /// Removes an edge from the graph.
    ///
    /// - Parameter edge: The edge to remove
    #if swift(>=6.2)
    mutating func remove(edge: consuming EdgeDescriptor)
    #else
    mutating func remove(edge: EdgeDescriptor)
    #endif
}

/// A protocol for graphs that support both vertex and edge modification.
///
/// Mutable graphs allow complete dynamic modification of both the vertex and edge sets,
/// providing full flexibility for graph construction and modification.
public protocol MutableGraph: VertexMutableGraph, EdgeMutableGraph {}
