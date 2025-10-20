typealias DefaultAdjacencyList = AdjacencyList<
    OrderedVertexStorage,
    CacheInOutEdges<OrderedEdgeStorage<OrderedVertexStorage.Vertex>>,
    DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
    DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
>

extension AdjacencyList: RandomGraphConstructible where
    VertexStore == OrderedVertexStorage,
    EdgeStore == CacheInOutEdges<OrderedEdgeStorage<OrderedVertexStorage.Vertex>>,
    VertexPropertyMap == DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
    EdgePropertyMap == DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
{}
