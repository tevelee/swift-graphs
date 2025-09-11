import Collections

extension EdgeStorage {
    static func ordered<Vertex>() -> OrderedEdgeStorage<Vertex> where Self == OrderedEdgeStorage<Vertex> {
        OrderedEdgeStorage()
    }
}

struct OrderedEdgeStorage<Vertex: Hashable>: EdgeStorage {
    struct Edge: Identifiable, Hashable {
        private let _id: Int
        var id: some Hashable { _id }
        fileprivate init(_id: Int) { self._id = _id }
    }

    private var _edges: OrderedDictionary<Edge, (source: Vertex, destination: Vertex)> = [:]
    private var _nextId: Int = 0

    var edgeCount: Int {
        _edges.count
    }

    func edges() -> OrderedSet<Edge> {
        _edges.keys
    }

    func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)? {
        _edges[edge]
    }

    func outgoingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        _edges.filter { $0.value.source == vertex }.keys
    }

    func outDegree(of vertex: Vertex) -> Int {
        outgoingEdges(of: vertex).count
    }

    func incomingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        _edges.filter { $0.value.destination == vertex }.keys
    }

    func inDegree(of vertex: Vertex) -> Int {
        incomingEdges(of: vertex).count
    }

    mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge {
        let edge = Edge(_id: _nextId)
        _nextId &+= 1
        _edges[edge] = (source, destination)
        return edge
    }
    
    mutating func remove(edge: Edge) {
        _edges[edge] = nil
    }
}
