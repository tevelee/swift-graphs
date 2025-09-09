struct AdjacencyList<
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
    var vertexStore: VertexStore
    var edgeStore: EdgeStore
    var vertexPropertyMap: VertexPropertyMap
    var edgePropertyMap: EdgePropertyMap
}

extension AdjacencyList where
    VertexStore == OrderedVertexStorage,
    EdgeStore == CacheInOutEdges<OrderedEdgeStorage<OrderedVertexStorage.Vertex>>,
    VertexPropertyMap == DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
    EdgePropertyMap == DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
{
    init() {
        self.init(edgeStore: OrderedEdgeStorage().cacheInOutEdges())
    }
}

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
extension AdjacencyList: BinaryIncidenceGraph where EdgeStore: BinaryEdgeStorage {}
extension AdjacencyList: MutableBinaryIncidenceGraph where EdgeStore: BinaryEdgeStorage {}
