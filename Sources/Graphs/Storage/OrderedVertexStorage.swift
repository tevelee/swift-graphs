import Collections
import Foundation

extension VertexStorage {
    static func ordered() -> OrderedVertexStorage where Self == OrderedVertexStorage {
        OrderedVertexStorage()
    }
}

typealias OVS = OrderedVertexStorage
struct OrderedVertexStorage: VertexStorage {
    struct Vertex: Identifiable, Hashable {
        private let _id: UUID

        var id: some Hashable { _id }

        fileprivate init() {
            _id = UUID()
        }
    }

    private var _vertices: OrderedSet<Vertex> = []

    var numberOfVertices: Int {
        _vertices.count
    }

    func vertices() -> OrderedSet<Vertex> {
        _vertices
    }

    func contains(_ vertex: Vertex) -> Bool {
        _vertices.contains(vertex)
    }

    mutating func addVertex() -> Vertex {
        let vertex = Vertex()
        _vertices.updateOrAppend(vertex)
        return vertex
    }

    mutating func remove(vertex: Vertex) {
        _vertices.remove(vertex)
    }
}
