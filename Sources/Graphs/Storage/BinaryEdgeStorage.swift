import Collections

struct BinaryEdgeStorage<Vertex: Hashable>: EdgeStorage {
    struct Edge: Identifiable, Hashable {
        private let _id: Int
        var id: some Hashable { _id }
        fileprivate init(_id: Int) { self._id = _id }
    }

    private var leftEdgeMap: [Vertex: Edge] = [:]
    private var rightEdgeMap: [Vertex: Edge] = [:]
    private var edgesStore: OrderedDictionary<Edge, (source: Vertex, destination: Vertex)> = [:]
    private var nextEdgeId: Int = 0

    // MARK: EdgeStorage conformance

    func edges() -> OrderedSet<Edge> { edgesStore.keys }
    var edgeCount: Int { edgesStore.count }

    func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)? {
        edgesStore[edge]
    }

    func outgoingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        var result: OrderedSet<Edge> = []
        if let e = leftEdgeMap[vertex] { result.updateOrAppend(e) }
        if let e = rightEdgeMap[vertex] { result.updateOrAppend(e) }
        return result
    }

    func outDegree(of vertex: Vertex) -> Int {
        (leftEdgeMap[vertex] != nil ? 1 : 0) + (rightEdgeMap[vertex] != nil ? 1 : 0)
    }

    func incomingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        var result: OrderedSet<Edge> = []
        for (edge, endpoints) in edgesStore where endpoints.destination == vertex {
            result.updateOrAppend(edge)
        }
        return result
    }

    func inDegree(of vertex: Vertex) -> Int {
        incomingEdges(of: vertex).count
    }

    @discardableResult
    mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge {
        if leftEdgeMap[source] == nil {
            let e = Edge(_id: nextEdgeId)
            nextEdgeId &+= 1
            leftEdgeMap[source] = e
            edgesStore[e] = (source, destination)
            return e
        } else if rightEdgeMap[source] == nil {
            let e = Edge(_id: nextEdgeId)
            nextEdgeId &+= 1
            rightEdgeMap[source] = e
            edgesStore[e] = (source, destination)
            return e
        } else {
            // Third child: replace right by policy; adjust as needed
            let e = Edge(_id: nextEdgeId)
            nextEdgeId &+= 1
            if let old = rightEdgeMap[source] {
                _ = edgesStore.removeValue(forKey: old)
            }
            rightEdgeMap[source] = e
            edgesStore[e] = (source, destination)
            return e
        }
    }

    mutating func remove(edge: consuming Edge) {
        guard let endpoints = edgesStore.removeValue(forKey: edge) else { return }
        let parent = endpoints.source
        if leftEdgeMap[parent] == edge {
            leftEdgeMap.removeValue(forKey: parent)
        }
        if rightEdgeMap[parent] == edge {
            rightEdgeMap.removeValue(forKey: parent)
        }
    }

    // MARK: Binary helpers
    func leftNeighbor(of v: Vertex) -> Vertex? { leftEdgeMap[v].flatMap { edgesStore[$0]?.destination } }
    func rightNeighbor(of v: Vertex) -> Vertex? { rightEdgeMap[v].flatMap { edgesStore[$0]?.destination } }
    func leftEdge(of v: Vertex) -> Edge? { leftEdgeMap[v] }
    func rightEdge(of v: Vertex) -> Edge? { rightEdgeMap[v] }
}


