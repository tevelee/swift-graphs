struct AdjacencyList<VertexStore: VertexStorage, EdgeStore: EdgeStorage, VertexPropertyMap: MutablePropertyMap, EdgePropertyMap: MutablePropertyMap> where
        EdgeStore.Vertex == VertexStore.Vertex,
        VertexPropertyMap.Key == VertexStore.Vertex,
        VertexPropertyMap.Value == VertexPropertyValues,
        EdgePropertyMap.Key == EdgeStore.Edge,
        EdgePropertyMap.Value == EdgePropertyValues
{
    private var vertexStorage: VertexStore
    private var edgeStorage: EdgeStore
    var vertexPropertyMap: VertexPropertyMap
    var edgePropertyMap: EdgePropertyMap

    init(
        vertexStorage: VertexStore = OVS(),
        edgeStorage: EdgeStore = OES().cacheInOutEdges(),
        vertexPropertyMap: VertexPropertyMap = DictionaryPropertyMap<OVS.Vertex, _>(
            defaultValue: VertexPropertyValues()
        ),
        edgePropertyMap: EdgePropertyMap = DictionaryPropertyMap<OES.Edge, _>(
            defaultValue: EdgePropertyValues()
        )
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
    func outgoingEdges(of vertex: VertexDescriptor) -> EdgeStore.Edges {
        edgeStorage.outgoingEdges(of: vertex)
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
    func incomingEdges(of vertex: VertexDescriptor) -> EdgeStore.Edges {
        edgeStorage.incomingEdges(of: vertex)
    }

    func inDegree(of vertex: VertexDescriptor) -> Int {
        edgeStorage.inDegree(of: vertex)
    }
}

extension AdjacencyList: VertexListGraph {
    func vertices() -> VertexStore.Vertices {
        vertexStorage.vertices()
    }

    var vertexCount: Int {
        vertexStorage.vertexCount
    }
}

extension AdjacencyList: EdgeListGraph {
    func edges() -> EdgeStore.Edges {
        edgeStorage.edges()
    }

    var edgeCount: Int {
        edgeStorage.edgeCount
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
        for edge in outgoingEdges(of: vertex) {
            remove(edge: edge)
        }
        for edge in incomingEdges(of: vertex) {
            remove(edge: edge)
        }
        vertexStorage.remove(vertex: vertex)
    }
}

extension AdjacencyList: PropertyGraph {}
extension AdjacencyList: MutablePropertyGraph {}
