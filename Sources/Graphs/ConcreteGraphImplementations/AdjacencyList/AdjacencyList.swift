struct AdjacencyList<VertexStore: VertexStorage, EdgeStore: EdgeStorage, VertexPropertyMap: MutablePropertyMap, EdgePropertyMap: MutablePropertyMap> where
        EdgeStore.Vertex == VertexStore.Vertex,
        VertexPropertyMap.Key == VertexStore.Vertex,
        VertexPropertyMap.Value == VertexPropertyValues,
        EdgePropertyMap.Key == EdgeStore.Edge,
        EdgePropertyMap.Value == EdgePropertyValues
{
    var vertexStore: VertexStore
    var edgeStore: EdgeStore
    var vertexPropertyMap: VertexPropertyMap
    var edgePropertyMap: EdgePropertyMap

    init(
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

// Zero-argument ergonomic initializer using ordered storages by default
extension AdjacencyList where
    VertexStore == OrderedVertexStorage,
    EdgeStore == CacheInOutEdges<OrderedEdgeStorage<OrderedVertexStorage.Vertex>>,
    VertexPropertyMap == DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
    EdgePropertyMap == DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
{
    init() {
        self.init(
            vertexStore: OrderedVertexStorage(),
            edgeStore: OrderedEdgeStorage<OrderedVertexStorage.Vertex>().cacheInOutEdges(),
            vertexPropertyMap: .init(defaultValue: .init()),
            edgePropertyMap: .init(defaultValue: .init())
        )
    }
}

// Ergonomic initializer that allows plugging any EdgeStore while defaulting VertexStore and maps
extension AdjacencyList where
    VertexStore == OrderedVertexStorage,
    VertexPropertyMap == DictionaryPropertyMap<VertexStore.Vertex, VertexPropertyValues>,
    EdgePropertyMap == DictionaryPropertyMap<EdgeStore.Edge, EdgePropertyValues>
{
    init(edgeStore: EdgeStore) {
        self.init(
            vertexStore: OrderedVertexStorage(),
            edgeStore: edgeStore,
            vertexPropertyMap: .init(defaultValue: .init()),
            edgePropertyMap: .init(defaultValue: .init())
        )
    }
}

extension AdjacencyList: Graph {
    typealias VertexDescriptor = VertexStore.Vertex
    typealias EdgeDescriptor = EdgeStore.Edge
}
extension AdjacencyList: VertexStorageBackedGraph {}
extension AdjacencyList: EdgeStorageBackedGraph {}
extension AdjacencyList: IncidenceGraph {
    typealias OutgoingEdges = EdgeStore.Edges
}
extension AdjacencyList: BidirectionalGraph {
    typealias IncomingEdges = EdgeStore.Edges
}
extension AdjacencyList: VertexListGraph {}
extension AdjacencyList: EdgeListGraph {}
extension AdjacencyList: AdjacencyGraph {}
extension AdjacencyList: MutableGraph {}
extension AdjacencyList: PropertyGraph {}
extension AdjacencyList: MutablePropertyGraph {}
