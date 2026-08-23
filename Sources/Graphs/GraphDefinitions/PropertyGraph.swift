/// A protocol for graphs that support vertex properties.
///
/// Vertex property graphs allow associating additional data with vertices
/// without modifying the graph structure itself.
public protocol VertexPropertyGraph: Graph {
    /// The type of properties associated with vertices.
    associatedtype VertexProperties: Graphs.VertexProperties

    /// Accesses the properties of a vertex.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: The properties associated with the vertex
    subscript(vertex: VertexDescriptor) -> VertexProperties { get }
}

extension VertexPropertyGraph where Self: VertexListGraph {
    /// Returns vertices that satisfy a given condition based on their properties.
    ///
    /// - Parameter condition: A closure that determines if a vertex's properties satisfy the condition
    /// - Returns: A lazy sequence of vertices whose properties satisfy the condition
    @inlinable
    public func vertices(satisfying condition: @escaping (VertexProperties) -> Bool) -> LazyFilterSequence<Vertices> {
        vertices().lazy.filter { condition(self[$0]) }
    }
}

/// A protocol for graphs that support edge properties.
///
/// Edge property graphs allow associating additional data with edges
/// without modifying the graph structure itself.
public protocol EdgePropertyGraph: Graph {
    /// The type of properties associated with edges.
    associatedtype EdgeProperties: Graphs.EdgeProperties

    /// Accesses the properties of an edge.
    ///
    /// - Parameter edge: The edge to query
    /// - Returns: The properties associated with the edge
    subscript(edge: EdgeDescriptor) -> EdgeProperties { get }
}

extension EdgePropertyGraph where Self: EdgeListGraph {
    /// Returns edges that satisfy a given condition based on their properties.
    ///
    /// - Parameter condition: A closure that determines if an edge's properties satisfy the condition
    /// - Returns: A lazy sequence of edges whose properties satisfy the condition
    @inlinable
    public func edges(satisfying condition: @escaping (EdgeProperties) -> Bool) -> LazyFilterSequence<Edges> {
        edges().lazy.filter { condition(self[$0]) }
    }
}

/// A protocol for graphs that support both vertex and edge properties.
///
/// Property graphs allow associating additional data with both vertices and edges,
/// providing a rich data model for graph-based applications.
public protocol PropertyGraph: VertexPropertyGraph, EdgePropertyGraph {}
