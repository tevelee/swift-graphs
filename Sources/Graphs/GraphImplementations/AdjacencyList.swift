import Collections

/// An adjacency list implementation of a graph.
///
/// This implementation uses separate storage for vertices and edges, providing
/// efficient access to neighbors and good space complexity for sparse graphs.
/// The implementation is generic over storage types, allowing for different
/// performance characteristics.
///
/// - Note: This implementation is optimized for sparse graphs where most vertex pairs
///   are not connected. For dense graphs, consider using `AdjacencyMatrix` instead.
public struct AdjacencyList<
    VertexStore: VertexStorage,
    EdgeStore: EdgeStorage,
    VertexPropertyMap: MutablePropertyMap,
    EdgePropertyMap: MutablePropertyMap
> where
    EdgeStore.Vertex == VertexStore.Vertex,
    VertexPropertyMap.Key == VertexStore.Vertex,
    VertexPropertyMap.Value == VertexPropertyValues,
    EdgePropertyMap.Key == EdgeStore.Edge,
    EdgePropertyMap.Value == EdgePropertyValues
{
    public var vertexStore: VertexStore
    public var edgeStore: EdgeStore
    public var vertexPropertyMap: VertexPropertyMap
    public var edgePropertyMap: EdgePropertyMap
    
    /// Creates a new adjacency list with the specified storage components.
    ///
    /// - Parameters:
    ///   - vertexStore: The storage for vertices
    ///   - edgeStore: The storage for edges
    ///   - vertexPropertyMap: The property map for vertex properties
    ///   - edgePropertyMap: The property map for edge properties
    @inlinable
    public init(
        vertexStore: VertexStore,
        edgeStore: EdgeStore,
        vertexPropertyMap: VertexPropertyMap,
        edgePropertyMap: EdgePropertyMap
    ) {
        self.vertexStore = vertexStore
        self.edgeStore = edgeStore
        self.vertexPropertyMap = vertexPropertyMap
        self.edgePropertyMap = edgePropertyMap
    }
}

extension AdjacencyList where
    VertexStore == OrderedVertexStorage,
    EdgeStore == CacheInOutEdges<OrderedEdgeStorage<OrderedVertexStorage.Vertex>>,
    VertexPropertyMap == DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
    EdgePropertyMap == DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
{
    /// Creates a new adjacency list with default storage components.
    @inlinable
    public init() {
        self.init(edgeStore: OrderedEdgeStorage().cacheInOutEdges())
    }
}

extension AdjacencyList where
    VertexStore == OrderedVertexStorage,
    VertexPropertyMap == DictionaryPropertyMap<VertexStore.Vertex, VertexPropertyValues>,
    EdgePropertyMap == DictionaryPropertyMap<EdgeStore.Edge, EdgePropertyValues>
{
    /// Creates a new adjacency list with the specified edge store and default other components.
    ///
    /// - Parameter edgeStore: The edge storage to use
    @inlinable
    public init(edgeStore: EdgeStore) {
        self.init(
            vertexStore: OrderedVertexStorage(),
            edgeStore: edgeStore,
            vertexPropertyMap: .init(defaultValue: .init()),
            edgePropertyMap: .init(defaultValue: .init())
        )
    }
}

extension AdjacencyList: Graph {
    public typealias VertexDescriptor = VertexStore.Vertex
    public typealias EdgeDescriptor = EdgeStore.Edge
}
extension AdjacencyList: VertexStorageBackedGraph {}
extension AdjacencyList: EdgeStorageBackedGraph {}
extension AdjacencyList: IncidenceGraph {
    public typealias OutgoingEdges = EdgeStore.Edges
}
extension AdjacencyList: BidirectionalGraph {
    public typealias IncomingEdges = EdgeStore.Edges
}
extension AdjacencyList: VertexListGraph {}
extension AdjacencyList: EdgeListGraph {}
extension AdjacencyList: AdjacencyGraph {}
extension AdjacencyList: MutableGraph {}
extension AdjacencyList: PropertyGraph {
    public typealias VertexProperties = VertexPropertyMap.Value
    public typealias EdgeProperties = EdgePropertyMap.Value
}
extension AdjacencyList: MutablePropertyGraph {}
extension AdjacencyList: BinaryIncidenceGraph where EdgeStore: BinaryEdgeStorage {}
extension AdjacencyList: MutableBinaryIncidenceGraph where EdgeStore: BinaryEdgeStorage {}

protocol AdjacencyListProtocol:
    Graph,
    VertexStorageBackedGraph,
    EdgeStorageBackedGraph,
    IncidenceGraph,
    BidirectionalGraph,
    VertexListGraph,
    EdgeListGraph,
    AdjacencyGraph,
    MutableGraph,
    PropertyGraph,
    MutablePropertyGraph {}

extension AdjacencyList: AdjacencyListProtocol where
    VertexStore == OrderedVertexStorage,
    EdgeStore == CacheInOutEdges<OrderedEdgeStorage<OrderedVertexStorage.Vertex>>,
    VertexPropertyMap == DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
    EdgePropertyMap == DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues> {}
