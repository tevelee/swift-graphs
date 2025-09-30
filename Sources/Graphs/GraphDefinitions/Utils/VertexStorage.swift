public protocol VertexStorage {
    associatedtype Vertex: Hashable
    associatedtype Vertices: Sequence<Vertex>

    mutating func addVertex() -> Vertex
    mutating func remove(vertex: Vertex)
    func contains(_ vertex: Vertex) -> Bool
    func vertices() -> Vertices
    var vertexCount: Int { get }
}
