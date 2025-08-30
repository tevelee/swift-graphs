protocol VertexListGraph: Graph {
    associatedtype Vertices: Sequence<VertexDescriptor>

    func vertices() -> Vertices
    var numberOfVertices: Int { get }
}
