/// A protocol for graphs that support vertex properties.
///
/// Vertex property graphs allow associating additional data with vertices
/// without modifying the graph structure itself.
public protocol VertexPropertyGraph: Graph {
    /// The type of properties associated with vertices.
    associatedtype VertexProperties: Graphs.VertexProperties
    
    /// The type of property map used to store vertex properties.
    associatedtype VertexPropertyMap: PropertyMap<VertexDescriptor, VertexProperties>

    /// The property map containing vertex properties.
    var vertexPropertyMap: VertexPropertyMap { get }
}

extension VertexPropertyGraph {
    /// Accesses the properties of a vertex.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: The properties associated with the vertex
    @inlinable
    public subscript(vertex: VertexPropertyMap.Key) -> VertexPropertyMap.Value {
        vertexPropertyMap[vertex]
    }
}

extension VertexPropertyGraph where Self: VertexListGraph {
    /// Returns vertices that satisfy a given condition based on their properties.
    ///
    /// - Parameter condition: A closure that determines if a vertex's properties satisfy the condition
    /// - Returns: A lazy sequence of vertices whose properties satisfy the condition
    @inlinable
    public func vertices(satisfying condition: @escaping (VertexProperties) -> Bool) -> LazyFilterSequence<Vertices> {
        vertices().lazy.filter { condition(vertexPropertyMap[$0]) }
    }
}

/// A protocol for graphs that support edge properties.
///
/// Edge property graphs allow associating additional data with edges
/// without modifying the graph structure itself.
public protocol EdgePropertyGraph: Graph {
    /// The type of properties associated with edges.
    associatedtype EdgeProperties: Graphs.EdgeProperties
    
    /// The type of property map used to store edge properties.
    associatedtype EdgePropertyMap: PropertyMap<EdgeDescriptor, EdgeProperties>

    /// The property map containing edge properties.
    var edgePropertyMap: EdgePropertyMap { get }
}

extension EdgePropertyGraph {
    /// Accesses the properties of an edge.
    ///
    /// - Parameter edge: The edge to query
    /// - Returns: The properties associated with the edge
    @inlinable
    public subscript(edge: EdgePropertyMap.Key) -> EdgePropertyMap.Value {
        edgePropertyMap[edge]
    }
}

extension EdgePropertyGraph where Self: EdgeListGraph {
    /// Returns edges that satisfy a given condition based on their properties.
    ///
    /// - Parameter condition: A closure that determines if an edge's properties satisfy the condition
    /// - Returns: A lazy sequence of edges whose properties satisfy the condition
    @inlinable
    public func edges(satisfying condition: @escaping (EdgeProperties) -> Bool) -> LazyFilterSequence<Edges> {
        edges().lazy.filter { condition(edgePropertyMap[$0]) }
    }
}

/// A protocol for graphs that support both vertex and edge properties.
///
/// Property graphs allow associating additional data with both vertices and edges,
/// providing a rich data model for graph-based applications.
public protocol PropertyGraph: VertexPropertyGraph, EdgePropertyGraph {}
