/// A graph wrapper that caches each vertex's edge computation on first access.
///
/// Unlike `CacheInOutEdges` (which eagerly pre-populates at initialisation), `MemoizedGraph`
/// defers computation and records each result the first time a vertex is queried. Subsequent
/// queries for the same vertex are served from the cache without calling the underlying graph.
///
/// This is most useful when wrapping a `LazyIncidenceGraph` whose edge closure is expensive
/// and the same vertices are visited repeatedly during an algorithm run.
///
/// The cache uses reference storage so copies of the wrapper share the same warm cache.
/// The cache is **not** thread-safe; use a single instance per execution context.
public struct MemoizedGraph<Base: IncidenceGraph> where Base.VertexDescriptor: Hashable {
    /// The underlying graph whose edge computations are being memoized.
    public let base: Base

    @usableFromInline
    final class Cache {
        @usableFromInline var outgoing: [Base.VertexDescriptor: [Base.EdgeDescriptor]] = [:]
        @usableFromInline var incoming: [Base.VertexDescriptor: [Base.EdgeDescriptor]] = [:]
        @inlinable init() {}
    }

    @usableFromInline
    let cache: Cache

    /// Creates a memoized wrapper around `base`.
    @inlinable
    public init(_ base: Base) {
        self.base = base
        self.cache = Cache()
    }

    /// Clears all cached edge data, forcing recomputation on the next access.
    @inlinable
    public func invalidate() {
        cache.outgoing.removeAll()
        cache.incoming.removeAll()
    }
}

// MARK: - Graph

extension MemoizedGraph: Graph {
    public typealias VertexDescriptor = Base.VertexDescriptor
    public typealias EdgeDescriptor = Base.EdgeDescriptor
}

// MARK: - IncidenceGraph

extension MemoizedGraph: IncidenceGraph {
    public typealias OutgoingEdges = [Base.EdgeDescriptor]

    @inlinable
    public func outgoingEdges(of vertex: Base.VertexDescriptor) -> [Base.EdgeDescriptor] {
        if let hit = cache.outgoing[vertex] { return hit }
        let edges = Array(base.outgoingEdges(of: vertex))
        cache.outgoing[vertex] = edges
        return edges
    }

    @inlinable
    public func source(of edge: Base.EdgeDescriptor) -> Base.VertexDescriptor? {
        base.source(of: edge)
    }

    @inlinable
    public func destination(of edge: Base.EdgeDescriptor) -> Base.VertexDescriptor? {
        base.destination(of: edge)
    }

    @inlinable
    public func outDegree(of vertex: Base.VertexDescriptor) -> Int {
        outgoingEdges(of: vertex).count
    }
}

// MARK: - BidirectionalGraph

extension MemoizedGraph: BidirectionalGraph where Base: BidirectionalGraph {
    public typealias IncomingEdges = [Base.EdgeDescriptor]

    @inlinable
    public func incomingEdges(of vertex: Base.VertexDescriptor) -> [Base.EdgeDescriptor] {
        if let hit = cache.incoming[vertex] { return hit }
        let edges = Array(base.incomingEdges(of: vertex))
        cache.incoming[vertex] = edges
        return edges
    }

    @inlinable
    public func inDegree(of vertex: Base.VertexDescriptor) -> Int {
        incomingEdges(of: vertex).count
    }
}

// MARK: - VertexListGraph

extension MemoizedGraph: VertexListGraph where Base: VertexListGraph {
    public typealias Vertices = Base.Vertices

    @inlinable
    public func vertices() -> Base.Vertices { base.vertices() }

    @inlinable
    public var vertexCount: Int { base.vertexCount }
}

// MARK: - EdgeListGraph

extension MemoizedGraph: EdgeListGraph where Base: EdgeListGraph {
    public typealias Edges = Base.Edges

    @inlinable
    public func edges() -> Base.Edges { base.edges() }

    @inlinable
    public var edgeCount: Int { base.edgeCount }
}

// MARK: - AdjacencyGraph

extension MemoizedGraph: AdjacencyGraph {
    public typealias AdjacentVertices = [Base.VertexDescriptor]

    /// Returns all vertices reachable via outgoing edges from `vertex`, using the memoized
    /// edge list so the underlying graph is not queried again for already-visited vertices.
    @inlinable
    public func adjacentVertices(of vertex: Base.VertexDescriptor) -> [Base.VertexDescriptor] {
        outgoingEdges(of: vertex).compactMap { destination(of: $0) }
    }
}

// MARK: - EdgeLookupGraph

extension MemoizedGraph: EdgeLookupGraph where Base: EdgeLookupGraph {
    @inlinable
    public func edge(from source: Base.VertexDescriptor, to destination: Base.VertexDescriptor) -> Base.EdgeDescriptor? {
        base.edge(from: source, to: destination)
    }
}

// MARK: - PropertyGraph

extension MemoizedGraph: VertexPropertyGraph where Base: VertexPropertyGraph {
    public typealias VertexProperties = Base.VertexProperties
    public typealias VertexPropertyMap = Base.VertexPropertyMap

    @inlinable
    public var vertexPropertyMap: Base.VertexPropertyMap { base.vertexPropertyMap }
}

extension MemoizedGraph: EdgePropertyGraph where Base: EdgePropertyGraph {
    public typealias EdgeProperties = Base.EdgeProperties
    public typealias EdgePropertyMap = Base.EdgePropertyMap

    @inlinable
    public var edgePropertyMap: Base.EdgePropertyMap { base.edgePropertyMap }
}

// MARK: - Factory

extension IncidenceGraph where VertexDescriptor: Hashable {
    /// Returns a memoized view of this graph that caches each vertex's outgoing edges on first
    /// access, so repeated queries for the same vertex skip the underlying computation.
    @inlinable
    public func memoized() -> MemoizedGraph<Self> {
        MemoizedGraph(self)
    }
}
