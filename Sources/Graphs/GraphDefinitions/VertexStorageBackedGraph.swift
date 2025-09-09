protocol VertexStorageBackedGraph: Graph {
    associatedtype VertexStore: VertexStorage where VertexStore.Vertex == VertexDescriptor
    var vertexStore: VertexStore { get set }
}

// Defaults for vertex listing via the backing store
extension VertexListGraph where Self: VertexStorageBackedGraph {
    func vertices() -> VertexStore.Vertices { vertexStore.vertices() }
    var vertexCount: Int { vertexStore.vertexCount }
}


