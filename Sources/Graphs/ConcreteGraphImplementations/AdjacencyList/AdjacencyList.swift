struct AdjacencyList<VertexStore: VertexStorage, EdgeStore: EdgeStorage, VertexPropertyMap: PropertyMap, EdgePropertyMap: PropertyMap> where EdgeStore.Vertex == VertexStore.Vertex, VertexPropertyMap.Key == VertexStore.Vertex, EdgePropertyMap.Key == EdgeStore.Edge {
    private var vertexStorage: VertexStore
    private var edgeStorage: EdgeStore
    var vertexPropertyMap: VertexPropertyMap
    var edgePropertyMap: EdgePropertyMap

    init(
        vertexStorage: VertexStore = OrderedVertexStorage(),
        edgeStorage: EdgeStore = OrderedEdgeStorage<OrderedVertexStorage.Vertex>().cacheInOutEdges(),
        vertexPropertyMap: VertexPropertyMap = NoProperty<OrderedVertexStorage.Vertex>(),
        edgePropertyMap: EdgePropertyMap = NoProperty<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge>()
    ) {
        self.vertexStorage = vertexStorage
        self.edgeStorage = edgeStorage
        self.vertexPropertyMap = vertexPropertyMap
        self.edgePropertyMap = edgePropertyMap
    }
}

extension AdjacencyList: Graph {
    typealias VertexDescriptor = VertexStore.Vertex
    typealias EdgeDescriptor = EdgeStore.Edge
}

extension AdjacencyList: IncidenceGraph {
    func outEdges(of vertex: VertexDescriptor) -> EdgeStore.Edges {
        edgeStorage.outEdges(of: vertex)
    }

    func source(of edge: EdgeDescriptor) -> VertexDescriptor? {
        edgeStorage.endpoints(of: edge)?.source
    }
    
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor? {
        edgeStorage.endpoints(of: edge)?.destination
    }
    
    func outDegree(of vertex: VertexDescriptor) -> Int {
        edgeStorage.outDegree(of: vertex)
    }
}

extension AdjacencyList: BidirectionalGraph {
    func inEdges(of vertex: VertexDescriptor) -> EdgeStore.Edges {
        edgeStorage.inEdges(of: vertex)
    }

    func inDegree(of vertex: VertexDescriptor) -> Int {
        edgeStorage.inDegree(of: vertex)
    }
}

extension AdjacencyList: VertexListGraph {
    func vertices() -> VertexStore.Vertices {
        vertexStorage.vertices()
    }

    var numberOfVertices: Int {
        vertexStorage.numberOfVertices
    }
}

extension AdjacencyList: EdgeListGraph {
    func edges() -> EdgeStore.Edges {
        edgeStorage.edges()
    }

    var numberOfEdges: Int {
        edgeStorage.numberOfEdges
    }
}

extension AdjacencyList: AdjacencyGraph {}

extension AdjacencyList: MutableGraph {
    @discardableResult
    mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor? {
        guard vertexStorage.contains(source), vertexStorage.contains(destination) else { return nil }
        return edgeStorage.addEdge(from: source, to: destination)
    }

    mutating func remove(edge: consuming EdgeDescriptor) {
        edgeStorage.remove(edge: edge)
    }

    mutating func addVertex() -> VertexDescriptor {
        vertexStorage.addVertex()
    }

    mutating func remove(vertex: consuming VertexDescriptor) {
        for edge in outEdges(of: vertex) {
            remove(edge: edge)
        }
        for edge in inEdges(of: vertex) {
            remove(edge: edge)
        }
        vertexStorage.remove(vertex: vertex)
    }
}

extension AdjacencyList: PropertyGraph {}
extension AdjacencyList: VertexMutablePropertyGraph where VertexPropertyMap: MutablePropertyMap {}
extension AdjacencyList: EdgeMutablePropertyGraph where EdgePropertyMap: MutablePropertyMap {}

extension AdjacencyList {
    func edgeProperty<P: GraphProperty>(_ property: P.Type) -> AdjacencyList<
        VertexStore,
        EdgeStore,
        VertexPropertyMap,
        CompositePropertyMap<EdgePropertyMap, DictionaryPropertyMap<EdgeStore.Edge, P>>
    > {
        .init(
            vertexStorage: vertexStorage,
            edgeStorage: edgeStorage,
            vertexPropertyMap: vertexPropertyMap,
            edgePropertyMap: edgePropertyMap.combined(with: DictionaryPropertyMap<EdgeStore.Edge, P>())
        )
    }

    func edgeProperty<P: GraphProperty>(_ property: P.Type) -> AdjacencyList<
        VertexStore,
        EdgeStore,
        VertexPropertyMap,
        DictionaryPropertyMap<EdgeStore.Edge, P>
    > where EdgePropertyMap == NoProperty<EdgeStore.Edge> {
        .init(
            vertexStorage: vertexStorage,
            edgeStorage: edgeStorage,
            vertexPropertyMap: vertexPropertyMap,
            edgePropertyMap: edgePropertyMap.combined(with: DictionaryPropertyMap<EdgeStore.Edge, P>())
        )
    }
}
