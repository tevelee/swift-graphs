protocol VertexStorageBackedGraph: Graph {
    associatedtype VertexStore: VertexStorage where VertexStore.Vertex == VertexDescriptor
    var vertexStore: VertexStore { get set }
}

extension VertexListGraph where Self: VertexStorageBackedGraph {
    func vertices() -> VertexStore.Vertices { vertexStore.vertices() }
    var vertexCount: Int { vertexStore.vertexCount }
}

extension MutableGraph where Self: VertexStorageBackedGraph & EdgeStorageBackedGraph {
    @discardableResult
    mutating func addVertex() -> VertexDescriptor { vertexStore.addVertex() }

    mutating func remove(edge: consuming EdgeDescriptor) { edgeStore.remove(edge: edge) }
}

extension MutableGraph where Self: VertexStorageBackedGraph & EdgeStorageBackedGraph & IncidenceGraph {
    @discardableResult
    mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor? {
        guard vertexStore.contains(source), vertexStore.contains(destination) else { return nil }
        return edgeStore.addEdge(from: source, to: destination)
    }

    mutating func remove(vertex: consuming VertexDescriptor) {
        for edge in outgoingEdges(of: vertex) { remove(edge: edge) }
        vertexStore.remove(vertex: vertex)
    }
}

extension MutableGraph where Self: VertexStorageBackedGraph & EdgeStorageBackedGraph & BidirectionalGraph {
    mutating func remove(vertex: consuming VertexDescriptor) {
        for edge in outgoingEdges(of: vertex) { remove(edge: edge) }
        for edge in incomingEdges(of: vertex) { remove(edge: edge) }
        vertexStore.remove(vertex: vertex)
    }
}


