#if !GRAPHS_USES_TRAITS || GRAPHS_GENERATION
    extension StorageBackedAdjacencyList: RandomGraphConstructible
    where
        VertexStore == OrderedVertexStorage,
        EdgeStore == CacheInOutEdges<OrderedEdgeStorage<OrderedVertexStorage.Vertex>>,
        VertexPropertyStore == DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
        EdgePropertyStore == DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
    {}
#endif
