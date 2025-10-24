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

/// A protocol that represents the full set of capabilities provided by an `AdjacencyList` graph.
///
/// `AdjacencyListProtocol` aggregates all graph protocols that `AdjacencyList` implements,
/// providing a convenient type-erased interface for algorithms that require comprehensive
/// graph operations. This includes support for:
///
/// - **Enumeration**: List all vertices or edges
/// - **Structure Access**: Get outgoing/incoming edges, adjacent vertices
/// - **Mutation**: Add and remove vertices and edges
/// - **Properties**: Attach data to vertices and edges
///
/// Use this protocol when you need to work with `AdjacencyList` instances without being
/// tied to specific storage backends or property map implementations.
///
/// ## Protocol Requirements
///
/// This protocol inherits from:
///
/// - `Graph`: Basic graph type with vertex and edge descriptors
/// - `VertexStorageBackedGraph`: Access to the underlying vertex storage
/// - `EdgeStorageBackedGraph`: Access to the underlying edge storage
/// - `IncidenceGraph`: Get outgoing edges from a vertex
/// - `BidirectionalGraph`: Get incoming edges from a vertex
/// - `VertexListGraph`: Enumerate all vertices in the graph
/// - `EdgeListGraph`: Enumerate all edges in the graph
/// - `AdjacencyGraph`: Get adjacent vertices directly (without edges)
/// - `MutableGraph`: Add and remove vertices and edges
/// - `PropertyGraph`: Read vertex and edge properties
/// - `MutablePropertyGraph`: Modify vertex and edge properties
/// ```
public protocol AdjacencyListProtocol<VertexDescriptor, EdgeDescriptor>:
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
