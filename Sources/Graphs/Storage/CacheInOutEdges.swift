import Collections

extension EdgeStorage where Edges == OrderedSet<Edge> {
    func cacheInOutEdges() -> CacheInOutEdges<Self> {
        CacheInOutEdges(base: self)
    }
}

struct CacheInOutEdges<Base: EdgeStorage>: EdgeStorage where Base.Edges == OrderedSet<Base.Edge> {
    typealias Vertex = Base.Vertex
    typealias Edge = Base.Edge

    var base: Base

    init(base: Base) {
        self.base = base
    }

    private var _outgoingEdges: OrderedDictionary<Vertex, OrderedSet<Edge>> = [:]
    private var _incomingEdges: OrderedDictionary<Vertex, OrderedSet<Edge>> = [:]

    func outgoingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        _outgoingEdges[vertex] ?? []
    }

    func outDegree(of vertex: Vertex) -> Int {
        outgoingEdges(of: vertex).count
    }

    func incomingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        _incomingEdges[vertex] ?? []
    }

    func inDegree(of vertex: Vertex) -> Int {
        incomingEdges(of: vertex).count
    }

    mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge {
        let edge = base.addEdge(from: source, to: destination)
        _outgoingEdges[source, default: []].updateOrAppend(edge)
        _incomingEdges[destination, default: []].updateOrAppend(edge)
        return edge
    }

    mutating func remove(edge: Edge) {
        if let (source, destination) = endpoints(of: edge) {
            _outgoingEdges[source]?.remove(edge)
            _incomingEdges[destination]?.remove(edge)
        }
        base.remove(edge: edge)
    }

    func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)? {
        base.endpoints(of: edge)
    }

    func edges() -> Base.Edges {
        base.edges()
    }

    var edgeCount: Int {
        base.edgeCount
    }
}
