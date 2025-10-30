import Collections

extension VertexStorage {
    /// Creates an ordered vertex storage instance.
    @inlinable
    public static func ordered() -> OrderedVertexStorage where Self == OrderedVertexStorage {
        OrderedVertexStorage()
    }
}

/// A vertex storage implementation using an ordered set.
///
/// This implementation maintains vertices in insertion order and provides
/// efficient lookup and iteration. It's commonly used as the default
/// vertex storage for adjacency list graphs.
public struct OrderedVertexStorage: VertexStorage {
    /// A vertex in the ordered vertex storage.
    public struct Vertex: Identifiable, Hashable {
        @usableFromInline
        let _id: Int
        public var id: some Hashable { _id }
        @inlinable
        public init(_id: Int) { self._id = _id }
    }

    @usableFromInline
    var _vertices: OrderedSet<Vertex> = []
    @usableFromInline
    var _nextId: Int = 0

    /// The number of vertices in storage.
    @inlinable
    public var vertexCount: Int {
        _vertices.count
    }

    /// Returns all vertices in storage.
    @inlinable
    public func vertices() -> OrderedSet<Vertex> {
        _vertices
    }

    /// Checks if a vertex exists in storage.
    ///
    /// - Parameter vertex: The vertex to check
    /// - Returns: `true` if the vertex exists, `false` otherwise
    @inlinable
    public func contains(_ vertex: Vertex) -> Bool {
        _vertices.contains(vertex)
    }

    /// Adds a new vertex to storage.
    ///
    /// - Returns: The newly created vertex
    @inlinable
    public mutating func addVertex() -> Vertex {
        let vertex = Vertex(_id: _nextId)
        _nextId &+= 1
        _vertices.updateOrAppend(vertex)
        return vertex
    }

    /// Removes a vertex from storage.
    ///
    /// - Parameter vertex: The vertex to remove
    @inlinable
    public mutating func remove(vertex: Vertex) {
        _vertices.remove(vertex)
    }
    
    /// Creates a new empty ordered vertex storage.
    @inlinable
    public init() {}
}
