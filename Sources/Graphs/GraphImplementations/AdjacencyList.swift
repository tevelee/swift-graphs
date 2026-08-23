import OrderedCollections

/// An adjacency-list graph with caller-selected storage adapters.
///
/// This implementation uses separate storage for vertices and edges, providing
/// efficient access to neighbors and good space complexity for sparse graphs.
/// The implementation is generic over storage types, allowing for different
/// performance characteristics.
///
/// - Note: This implementation is optimized for sparse graphs where most vertex pairs
///   are not connected. For dense graphs, consider using `AdjacencyMatrix` instead.
public struct StorageBackedAdjacencyList<
    VertexStore: VertexStorage,
    EdgeStore: EdgeStorage,
    VertexPropertyStore: MutablePropertyMap,
    EdgePropertyStore: MutablePropertyMap
>
where
    EdgeStore.Vertex == VertexStore.Vertex,
    VertexPropertyStore.Key == VertexStore.Vertex,
    VertexPropertyStore.Value == VertexPropertyValues,
    EdgePropertyStore.Key == EdgeStore.Edge,
    EdgePropertyStore.Value == EdgePropertyValues
{
    @usableFromInline
    var vertexStorage: VertexStore
    @usableFromInline
    var edgeStorage: EdgeStore
    @usableFromInline
    var vertexPropertyStorage: VertexPropertyStore
    @usableFromInline
    var edgePropertyStorage: EdgePropertyStore

    /// Creates a new adjacency list with the specified storage components.
    ///
    /// - Parameters:
    ///   - vertexStorage: The storage for vertices.
    ///   - edgeStorage: The storage for edges.
    ///   - vertexPropertyStorage: The property storage for vertices.
    ///   - edgePropertyStorage: The property storage for edges.
    @inlinable
    public init(
        vertexStorage: VertexStore,
        edgeStorage: EdgeStore,
        vertexPropertyStorage: VertexPropertyStore,
        edgePropertyStorage: EdgePropertyStore
    ) {
        self.vertexStorage = vertexStorage
        self.edgeStorage = edgeStorage
        self.vertexPropertyStorage = vertexPropertyStorage
        self.edgePropertyStorage = edgePropertyStorage
    }
}

/// The general-purpose adjacency-list graph.
///
/// This graph uses insertion-ordered vertex and edge descriptors, caches incoming
/// edges, and stores vertex and edge properties in dictionaries.
public typealias AdjacencyList = StorageBackedAdjacencyList<
    OrderedVertexStorage,
    CacheInOutEdges<OrderedEdgeStorage<OrderedVertexStorage.Vertex>>,
    DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
    DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
>

extension StorageBackedAdjacencyList
where
    VertexStore == OrderedVertexStorage,
    EdgeStore == CacheInOutEdges<OrderedEdgeStorage<OrderedVertexStorage.Vertex>>,
    VertexPropertyStore == DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
    EdgePropertyStore == DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
{
    /// Creates a new adjacency list with default storage components.
    @inlinable
    public init() {
        self.init(edgeStorage: OrderedEdgeStorage().cacheInOutEdges())
    }
}

extension StorageBackedAdjacencyList
where
    VertexStore == OrderedVertexStorage,
    VertexPropertyStore == DictionaryPropertyMap<VertexStore.Vertex, VertexPropertyValues>,
    EdgePropertyStore == DictionaryPropertyMap<EdgeStore.Edge, EdgePropertyValues>
{
    /// Creates a new adjacency list with the specified edge store and default other components.
    ///
    /// - Parameter edgeStorage: The edge storage to use.
    @inlinable
    public init(edgeStorage: EdgeStore) {
        self.init(
            vertexStorage: OrderedVertexStorage(),
            edgeStorage: edgeStorage,
            vertexPropertyStorage: .init(defaultValue: .init()),
            edgePropertyStorage: .init(defaultValue: .init())
        )
    }
}

extension StorageBackedAdjacencyList: Graph {
    public typealias VertexDescriptor = VertexStore.Vertex
    public typealias EdgeDescriptor = EdgeStore.Edge
}
extension StorageBackedAdjacencyList: IncidenceGraph {
    public typealias OutgoingEdges = EdgeStore.Edges

    @inlinable
    public func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges {
        edgeStorage.outgoingEdges(of: vertex)
    }

    @inlinable
    public func source(of edge: EdgeDescriptor) -> VertexDescriptor? {
        edgeStorage.endpoints(of: edge)?.source
    }

    @inlinable
    public func destination(of edge: EdgeDescriptor) -> VertexDescriptor? {
        edgeStorage.endpoints(of: edge)?.destination
    }

    @inlinable
    public func outDegree(of vertex: VertexDescriptor) -> Int {
        edgeStorage.outDegree(of: vertex)
    }
}
extension StorageBackedAdjacencyList: BidirectionalGraph {
    public typealias IncomingEdges = EdgeStore.Edges

    @inlinable
    public func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges {
        edgeStorage.incomingEdges(of: vertex)
    }

    @inlinable
    public func inDegree(of vertex: VertexDescriptor) -> Int {
        edgeStorage.inDegree(of: vertex)
    }
}
extension StorageBackedAdjacencyList: VertexListGraph {
    public typealias Vertices = VertexStore.Vertices

    @inlinable
    public func vertices() -> Vertices {
        vertexStorage.vertices()
    }

    @inlinable
    public var vertexCount: Int {
        vertexStorage.vertexCount
    }
}
extension StorageBackedAdjacencyList: EdgeListGraph {
    public typealias Edges = EdgeStore.Edges

    @inlinable
    public func edges() -> Edges {
        edgeStorage.edges()
    }

    @inlinable
    public var edgeCount: Int {
        edgeStorage.edgeCount
    }
}
extension StorageBackedAdjacencyList: AdjacencyGraph {}
extension StorageBackedAdjacencyList: MutableGraph {
    @discardableResult
    @inlinable
    public mutating func addVertex() -> VertexDescriptor {
        vertexStorage.addVertex()
    }

    @discardableResult
    @inlinable
    public mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor? {
        guard vertexStorage.contains(source), vertexStorage.contains(destination) else { return nil }
        return edgeStorage.addEdge(from: source, to: destination)
    }

    #if swift(>=6.2)
        @inlinable
        public mutating func remove(edge: consuming EdgeDescriptor) {
            edgeStorage.remove(edge: edge)
        }

        @inlinable
        public mutating func remove(vertex: consuming VertexDescriptor) {
            for edge in outgoingEdges(of: vertex) { remove(edge: edge) }
            for edge in incomingEdges(of: vertex) { remove(edge: edge) }
            vertexStorage.remove(vertex: vertex)
        }
    #else
        @inlinable
        public mutating func remove(edge: EdgeDescriptor) {
            edgeStorage.remove(edge: edge)
        }

        @inlinable
        public mutating func remove(vertex: VertexDescriptor) {
            for edge in outgoingEdges(of: vertex) { remove(edge: edge) }
            for edge in incomingEdges(of: vertex) { remove(edge: edge) }
            vertexStorage.remove(vertex: vertex)
        }
    #endif
}
extension StorageBackedAdjacencyList: PropertyGraph {
    public typealias VertexProperties = VertexPropertyStore.Value
    public typealias EdgeProperties = EdgePropertyStore.Value

    #if compiler(>=6.2)
        @inlinable
        public subscript(vertex: VertexDescriptor) -> VertexProperties {
            set { vertexPropertyStorage[vertex] = newValue }
            _read { yield vertexPropertyStorage[vertex] }
            _modify {
                var properties = vertexPropertyStorage[vertex]
                defer { vertexPropertyStorage[vertex] = properties }
                yield &properties
            }
        }

        @inlinable
        public subscript(edge: EdgeDescriptor) -> EdgeProperties {
            set { edgePropertyStorage[edge] = newValue }
            _read { yield edgePropertyStorage[edge] }
            _modify {
                var properties = edgePropertyStorage[edge]
                defer { edgePropertyStorage[edge] = properties }
                yield &properties
            }
        }
    #else
        @inlinable
        public subscript(vertex: VertexDescriptor) -> VertexProperties {
            get { vertexPropertyStorage[vertex] }
            set { vertexPropertyStorage[vertex] = newValue }
        }

        @inlinable
        public subscript(edge: EdgeDescriptor) -> EdgeProperties {
            get { edgePropertyStorage[edge] }
            set { edgePropertyStorage[edge] = newValue }
        }
    #endif
}
extension StorageBackedAdjacencyList: MutablePropertyGraph {}
extension StorageBackedAdjacencyList: BinaryIncidenceGraph where EdgeStore: BinaryEdgeStorage {
    @inlinable
    public func leftEdge(of vertex: VertexDescriptor) -> EdgeDescriptor? {
        edgeStorage.leftEdge(of: vertex)
    }

    @inlinable
    public func rightEdge(of vertex: VertexDescriptor) -> EdgeDescriptor? {
        edgeStorage.rightEdge(of: vertex)
    }
}
extension StorageBackedAdjacencyList: MutableBinaryIncidenceGraph where EdgeStore: BinaryEdgeStorage {}

extension StorageBackedAdjacencyList: Sendable
where
    VertexStore: Sendable,
    EdgeStore: Sendable,
    VertexPropertyStore: Sendable,
    EdgePropertyStore: Sendable
{}
