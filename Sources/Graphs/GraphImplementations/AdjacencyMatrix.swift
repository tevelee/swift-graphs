import Collections

/// An adjacency matrix implementation of a graph.
///
/// This implementation uses a square boolean matrix to represent graph connectivity,
/// where `matrix[i][j]` is `true` if there is an edge from vertex `i` to vertex `j`.
/// This provides O(1) edge existence checks but O(V²) space complexity.
///
/// - Note: This implementation is optimized for dense graphs where most vertex pairs
///   are connected. For sparse graphs, consider using `AdjacencyList` instead.
public struct AdjacencyMatrix {
    // Square matrix (bool presence). For multigraphs, switch to Int counts or edge lists per cell.
    @usableFromInline
    internal var matrix: [[Bool]] = []
    @usableFromInline
    internal var verticesStore: OrderedSet<Vertex> = []
    @usableFromInline
    internal var edgesStore: OrderedDictionary<Edge, (source: Vertex, destination: Vertex)> = [:]
    // Performance optimization: O(1) edge lookup by (source, destination) pair
    @usableFromInline
    internal var edgeLookup: [Vertex: [Vertex: Edge]] = [:]
    @usableFromInline
    internal var nextVertexId: Int = 0
    @usableFromInline
    internal var nextEdgeId: Int = 0
    // Property maps
    public var vertexPropertyMap: DictionaryPropertyMap<Vertex, VertexPropertyValues> = .init(defaultValue: .init())
    public var edgePropertyMap: DictionaryPropertyMap<Edge, EdgePropertyValues> = .init(defaultValue: .init())
    
    /// Creates a new empty adjacency matrix.
    @inlinable
    public init() {}
}

extension AdjacencyMatrix: Graph {
    /// A vertex in the adjacency matrix graph.
    public struct Vertex: Identifiable, Hashable {
        private let _id: Int
        public var id: some Hashable { _id }
        @usableFromInline
        init(_id: Int) { self._id = _id }
    }

    /// An edge in the adjacency matrix graph.
    public struct Edge: Identifiable, Hashable {
        private let _id: Int
        public var id: some Hashable { _id }
        @usableFromInline
        init(_id: Int) { self._id = _id }
    }

    public typealias VertexDescriptor = Vertex
    public typealias EdgeDescriptor = Edge
}

extension AdjacencyMatrix: EdgeLookupGraph {
    @inlinable
    public func edge(from source: Vertex, to destination: Vertex) -> Edge? {
        guard let i = index(of: source), let j = index(of: destination) else { return nil }
        guard matrix[i][j] else { return nil }
        // O(1) edge lookup using the optimized lookup table
        return edgeLookup[source]?[destination]
    }
}

extension AdjacencyMatrix: VertexListGraph {
    @inlinable
    public func vertices() -> OrderedSet<Vertex> { verticesStore }
    
    @inlinable
    public var vertexCount: Int { verticesStore.count }
}

extension AdjacencyMatrix: EdgeListGraph {
    @inlinable
    public func edges() -> OrderedSet<Edge> { edgesStore.keys }
    
    @inlinable
    public var edgeCount: Int { edgesStore.count }
}

extension AdjacencyMatrix: IncidenceGraph {
    @inlinable
    public func outgoingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        guard let i = index(of: vertex) else { return [] }
        var result: OrderedSet<Edge> = []
        for j in 0 ..< matrix.count {
            if matrix[i][j] {
                if let e = edge(from: vertex, to: verticesStore[j]) { result.updateOrAppend(e) }
            }
        }
        return result
    }

    @inlinable
    public func source(of edge: Edge) -> Vertex? { edgesStore[edge]?.source }
    
    @inlinable
    public func destination(of edge: Edge) -> Vertex? { edgesStore[edge]?.destination }
    
    @inlinable
    public func outDegree(of vertex: Vertex) -> Int { outgoingEdges(of: vertex).count }
}

extension AdjacencyMatrix: BidirectionalGraph {
    @inlinable
    public func incomingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        guard let j = index(of: vertex) else { return [] }
        var result: OrderedSet<Edge> = []
        for i in 0 ..< matrix.count {
            if matrix[i][j] {
                if let e = edge(from: verticesStore[i], to: vertex) { result.updateOrAppend(e) }
            }
        }
        return result
    }
    
    @inlinable
    public func inDegree(of vertex: Vertex) -> Int { incomingEdges(of: vertex).count }
}

extension AdjacencyMatrix: MutableGraph {
    @discardableResult
    @inlinable
    public mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge? {
        guard let i = index(of: source), let j = index(of: destination) else { return nil }
        if matrix[i][j] {
            // Already exists; return the existing edge id
            if let e = edgeLookup[source]?[destination] { return e }
        }
        matrix[i][j] = true
        let e = Edge(_id: nextEdgeId)
        nextEdgeId &+= 1
        edgesStore[e] = (source, destination)
        // Update the O(1) lookup table
        edgeLookup[source, default: [:]][destination] = e
        return e
    }

    #if swift(>=6.2)
    @inlinable
    public mutating func remove(edge: consuming Edge) {
        guard let ep = edgesStore.removeValue(forKey: edge) else { return }
        if let i = index(of: ep.source), let j = index(of: ep.destination) { matrix[i][j] = false }
        // Update the O(1) lookup table
        edgeLookup[ep.source]?[ep.destination] = nil
        if edgeLookup[ep.source]?.isEmpty == true {
            edgeLookup[ep.source] = nil
        }
    }
    #else
    @inlinable
    public mutating func remove(edge: Edge) {
        guard let ep = edgesStore.removeValue(forKey: edge) else { return }
        if let i = index(of: ep.source), let j = index(of: ep.destination) { matrix[i][j] = false }
        // Update the O(1) lookup table
        edgeLookup[ep.source]?[ep.destination] = nil
        if edgeLookup[ep.source]?.isEmpty == true {
            edgeLookup[ep.source] = nil
        }
    }
    #endif

    @inlinable
    public mutating func addVertex() -> Vertex {
        let v = Vertex(_id: nextVertexId)
        nextVertexId &+= 1
        verticesStore.updateOrAppend(v)
        // Grow matrix
        let n = verticesStore.count
        for i in 0 ..< matrix.count { matrix[i].append(false) }
        matrix.append(Array(repeating: false, count: n))
        return v
    }

    #if swift(>=6.2)
    @inlinable
    public mutating func remove(vertex: consuming Vertex) {
        guard let idx = index(of: vertex) else { return }
        // Remove incident edges
        for e in outgoingEdges(of: vertex) { edgesStore.removeValue(forKey: e) }
        for e in incomingEdges(of: vertex) { edgesStore.removeValue(forKey: e) }
        // Clean up the O(1) lookup table
        edgeLookup[vertex] = nil
        for (source, var destinations) in edgeLookup {
            destinations[vertex] = nil
            if destinations.isEmpty {
                edgeLookup[source] = nil
            } else {
                edgeLookup[source] = destinations
            }
        }
        // Remove row and column
        matrix.remove(at: idx)
        for i in 0 ..< matrix.count { matrix[i].remove(at: idx) }
        verticesStore.remove(vertex)
    }
    #else
    @inlinable
    public mutating func remove(vertex: Vertex) {
        guard let idx = index(of: vertex) else { return }
        // Remove incident edges
        for e in outgoingEdges(of: vertex) { edgesStore.removeValue(forKey: e) }
        for e in incomingEdges(of: vertex) { edgesStore.removeValue(forKey: e) }
        // Clean up the O(1) lookup table
        edgeLookup[vertex] = nil
        for (source, var destinations) in edgeLookup {
            destinations[vertex] = nil
            if destinations.isEmpty {
                edgeLookup[source] = nil
            } else {
                edgeLookup[source] = destinations
            }
        }
        // Remove row and column
        matrix.remove(at: idx)
        for i in 0 ..< matrix.count { matrix[i].remove(at: idx) }
        verticesStore.remove(vertex)
    }
    #endif
}

extension AdjacencyMatrix: AdjacencyGraph {
    @inlinable
    public func adjacentVertices(of vertex: Vertex) -> OrderedSet<Vertex> {
        guard let idx = index(of: vertex) else { return [] }
        var result: OrderedSet<Vertex> = []
        // Outgoing neighbors: row scan
        for j in 0 ..< matrix.count {
            if matrix[idx][j] { result.updateOrAppend(verticesStore[j]) }
        }
        // Incoming neighbors: column scan
        for i in 0 ..< matrix.count {
            if matrix[i][idx] { result.updateOrAppend(verticesStore[i]) }
        }
        return result
    }
}

extension AdjacencyMatrix: PropertyGraph {
    public typealias VertexPropertyMap = DictionaryPropertyMap<Vertex, VertexPropertyValues>
    public typealias EdgePropertyMap = DictionaryPropertyMap<Edge, EdgePropertyValues>
}

extension AdjacencyMatrix: MutablePropertyGraph {}

extension AdjacencyMatrix {
    @usableFromInline
    func index(of v: Vertex) -> Int? { verticesStore.firstIndex(of: v) }
}


