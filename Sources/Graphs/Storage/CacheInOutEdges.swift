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

    private var _outEdges: OrderedDictionary<Vertex, OrderedSet<Edge>> = [:]
    private var _inEdges: OrderedDictionary<Vertex, OrderedSet<Edge>> = [:]

    func outEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        _outEdges[vertex] ?? []
    }

    func outDegree(of vertex: Vertex) -> Int {
        outEdges(of: vertex).count
    }

    func inEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        _inEdges[vertex] ?? []
    }

    func inDegree(of vertex: Vertex) -> Int {
        inEdges(of: vertex).count
    }

    mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge {
        let edge = base.addEdge(from: source, to: destination)
        _outEdges[source, default: []].updateOrAppend(edge)
        _inEdges[destination, default: []].updateOrAppend(edge)
        return edge
    }

    mutating func remove(edge: Edge) {
        if let (source, destination) = endpoints(of: edge) {
            _outEdges[source]?.remove(edge)
            _inEdges[destination]?.remove(edge)
        }
        base.remove(edge: edge)
    }

    func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)? {
        base.endpoints(of: edge)
    }

    func edges() -> Base.Edges {
        base.edges()
    }

    var numberOfEdges: Int {
        base.numberOfEdges
    }
}
