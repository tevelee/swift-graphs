protocol VertexListGraph: Graph {
    associatedtype Vertices: Sequence<VertexDescriptor>

    func vertices() -> Vertices
    var vertexCount: Int { get }
}
