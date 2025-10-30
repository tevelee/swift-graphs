import Collections

extension EdgeStorage {
    /// Creates an ordered edge storage instance.
    @inlinable
    public static func ordered<Vertex>() -> OrderedEdgeStorage<Vertex> where Self == OrderedEdgeStorage<Vertex> {
        OrderedEdgeStorage()
    }
}

/// An edge storage implementation using an ordered dictionary.
///
/// This implementation maintains edges in insertion order and provides
/// efficient lookup and iteration. It's commonly used as the default
/// edge storage for adjacency list graphs.
public struct OrderedEdgeStorage<Vertex: Hashable>: EdgeStorage {
    /// An edge in the ordered edge storage.
    public struct Edge: Identifiable, Hashable {
        private let _id: Int
        public var id: some Hashable { _id }
        @usableFromInline
        init(_id: Int) { self._id = _id }
    }

    @usableFromInline
    var _edges: OrderedDictionary<Edge, (source: Vertex, destination: Vertex)> = [:]
    @usableFromInline
    var _nextId: Int = 0

    /// The number of edges in storage.
    @inlinable
    public var edgeCount: Int {
        _edges.count
    }

    /// Returns all edges in storage.
    @inlinable
    public func edges() -> OrderedSet<Edge> {
        _edges.keys
    }

    /// Returns the endpoints of an edge.
    ///
    /// - Parameter edge: The edge to query
    /// - Returns: A tuple containing the source and destination vertices, or `nil` if the edge doesn't exist
    @inlinable
    public func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)? {
        _edges[edge]
    }

    /// Returns all outgoing edges from a vertex.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: A set of edges originating from the vertex
    @inlinable
    public func outgoingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        _edges.filter { $0.value.source == vertex }.keys
    }

    /// Returns the out-degree of a vertex.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: The number of outgoing edges from the vertex
    @inlinable
    public func outDegree(of vertex: Vertex) -> Int {
        outgoingEdges(of: vertex).count
    }

    /// Returns all incoming edges to a vertex.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: A set of edges terminating at the vertex
    @inlinable
    public func incomingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        _edges.filter { $0.value.destination == vertex }.keys
    }

    /// Returns the in-degree of a vertex.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: The number of incoming edges to the vertex
    @inlinable
    public func inDegree(of vertex: Vertex) -> Int {
        incomingEdges(of: vertex).count
    }

    /// Adds a new edge to storage.
    ///
    /// - Parameters:
    ///   - source: The source vertex of the edge
    ///   - destination: The destination vertex of the edge
    /// - Returns: The newly created edge
    @inlinable
    public mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge {
        let edge = Edge(_id: _nextId)
        _nextId &+= 1
        _edges[edge] = (source, destination)
        return edge
    }
    
    /// Removes an edge from storage.
    ///
    /// - Parameter edge: The edge to remove
    @inlinable
    public mutating func remove(edge: Edge) {
        _edges[edge] = nil
    }
    
    /// Creates a new empty ordered edge storage.
    @inlinable
    public init() {}
}
