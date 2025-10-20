import Collections

extension EdgeStorage where Edges == OrderedSet<Edge> {
    @inlinable
    public func cacheInOutEdges() -> CacheInOutEdges<Self> {
        CacheInOutEdges(base: self)
    }
}

/// An edge storage wrapper that caches incoming and outgoing edges for performance.
///
/// This wrapper maintains separate caches for incoming and outgoing edges to provide
/// O(1) access to edge lists, which is especially useful for algorithms that frequently
/// query the incidence structure of a graph.
public struct CacheInOutEdges<
    Base: EdgeStorage
>: EdgeStorage where
    Base.Edges == OrderedSet<Base.Edge>
{
    public typealias Vertex = Base.Vertex
    public typealias Edge = Base.Edge

    public var base: Base

    /// Creates a new cached edge storage wrapper.
    ///
    /// - Parameter base: The underlying edge storage to wrap
    @inlinable
    public init(base: Base) {
        self.base = base
        // Hydrate caches for pre-populated storages
        for edge in base.edges() {
            if let (source, destination) = base.endpoints(of: edge) {
                _outgoingEdges[source, default: []].updateOrAppend(edge)
                _incomingEdges[destination, default: []].updateOrAppend(edge)
            }
        }
    }

    @usableFromInline
    var _outgoingEdges: OrderedDictionary<Vertex, OrderedSet<Edge>> = [:]
    @usableFromInline
    var _incomingEdges: OrderedDictionary<Vertex, OrderedSet<Edge>> = [:]

    /// Returns all outgoing edges from a vertex.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: A set of edges originating from the vertex
    @inlinable
    public func outgoingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        _outgoingEdges[vertex] ?? []
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
        _incomingEdges[vertex] ?? []
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
        let edge = base.addEdge(from: source, to: destination)
        _outgoingEdges[source, default: []].updateOrAppend(edge)
        _incomingEdges[destination, default: []].updateOrAppend(edge)
        return edge
    }

    /// Removes an edge from storage.
    ///
    /// - Parameter edge: The edge to remove
    @inlinable
    public mutating func remove(edge: Edge) {
        if let (source, destination) = endpoints(of: edge) {
            _outgoingEdges[source]?.remove(edge)
            _incomingEdges[destination]?.remove(edge)
        }
        base.remove(edge: edge)
    }

    /// Returns the endpoints of an edge.
    ///
    /// - Parameter edge: The edge to query
    /// - Returns: A tuple containing the source and destination vertices, or `nil` if the edge doesn't exist
    @inlinable
    public func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)? {
        base.endpoints(of: edge)
    }

    /// Returns all edges in storage.
    @inlinable
    public func edges() -> Base.Edges {
        base.edges()
    }

    /// The number of edges in storage.
    @inlinable
    public var edgeCount: Int {
        base.edgeCount
    }
}
