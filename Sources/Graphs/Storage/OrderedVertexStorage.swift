import Collections

extension VertexStorage {
    static func ordered() -> OrderedVertexStorage where Self == OrderedVertexStorage {
        OrderedVertexStorage()
    }
}

typealias OVS = OrderedVertexStorage
struct OrderedVertexStorage: VertexStorage {
    struct Vertex: Identifiable, Hashable {
        private let _id: Int
        var id: some Hashable { _id }
        fileprivate init(_id: Int) { self._id = _id }
    }

    private var _vertices: OrderedSet<Vertex> = []
    private var _nextId: Int = 0

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
        let vertex = Vertex(_id: _nextId)
        _nextId &+= 1
        _vertices.updateOrAppend(vertex)
        return vertex
    }

    mutating func remove(vertex: Vertex) {
        _vertices.remove(vertex)
    }
}
