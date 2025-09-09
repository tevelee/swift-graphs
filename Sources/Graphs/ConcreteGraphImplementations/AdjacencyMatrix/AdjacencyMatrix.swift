import Collections

struct AdjacencyMatrix {
    // Square matrix (bool presence). For multigraphs, switch to Int counts or edge lists per cell.
    private var matrix: [[Bool]] = []
    private var verticesStore: OrderedSet<Vertex> = []
    private var edgesStore: OrderedDictionary<Edge, (source: Vertex, destination: Vertex)> = [:]
    private var nextVertexId: Int = 0
    private var nextEdgeId: Int = 0
}

extension AdjacencyMatrix: Graph {
    struct Vertex: Identifiable, Hashable {
        private let _id: Int
        var id: some Hashable { _id }
        fileprivate init(_id: Int) { self._id = _id }
    }

    struct Edge: Identifiable, Hashable {
        private let _id: Int
        var id: some Hashable { _id }
        fileprivate init(_id: Int) { self._id = _id }
    }

    typealias VertexDescriptor = Vertex
    typealias EdgeDescriptor = Edge
}

extension AdjacencyMatrix: EdgeLookupGraph {
    func edge(from source: Vertex, to destination: Vertex) -> Edge? {
        guard let i = index(of: source), let j = index(of: destination) else { return nil }
        guard matrix[i][j] else { return nil }
        // Linear search to return stable edge descriptor
        for (e, ep) in edgesStore where ep.source == source && ep.destination == destination { return e }
        return nil
    }
}

extension AdjacencyMatrix: VertexListGraph {
    func vertices() -> OrderedSet<Vertex> { verticesStore }
    var vertexCount: Int { verticesStore.count }
}

extension AdjacencyMatrix: EdgeListGraph {
    func edges() -> OrderedSet<Edge> { edgesStore.keys }
    var edgeCount: Int { edgesStore.count }
}

extension AdjacencyMatrix: IncidenceGraph {
    func outgoingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        guard let i = index(of: vertex) else { return [] }
        var result: OrderedSet<Edge> = []
        for j in 0..<matrix.count {
            if matrix[i][j] {
                if let e = edge(from: vertex, to: verticesStore[j]) { result.updateOrAppend(e) }
            }
        }
        return result
    }

    func source(of edge: Edge) -> Vertex? { edgesStore[edge]?.source }
    func destination(of edge: Edge) -> Vertex? { edgesStore[edge]?.destination }
    func outDegree(of vertex: Vertex) -> Int { outgoingEdges(of: vertex).count }
}

extension AdjacencyMatrix: BidirectionalGraph {
    func incomingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        guard let j = index(of: vertex) else { return [] }
        var result: OrderedSet<Edge> = []
        for i in 0..<matrix.count {
            if matrix[i][j] {
                if let e = edge(from: verticesStore[i], to: vertex) { result.updateOrAppend(e) }
            }
        }
        return result
    }
    func inDegree(of vertex: Vertex) -> Int { incomingEdges(of: vertex).count }
}

extension AdjacencyMatrix: MutableGraph {
    @discardableResult
    mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge? {
        guard let i = index(of: source), let j = index(of: destination) else { return nil }
        if matrix[i][j] {
            // Already exists; return the existing edge id
            if let e = edge(from: source, to: destination) { return e }
        }
        matrix[i][j] = true
        let e = Edge(_id: nextEdgeId)
        nextEdgeId &+= 1
        edgesStore[e] = (source, destination)
        return e
    }

    mutating func remove(edge: consuming Edge) {
        guard let ep = edgesStore.removeValue(forKey: edge) else { return }
        if let i = index(of: ep.source), let j = index(of: ep.destination) { matrix[i][j] = false }
    }

    mutating func addVertex() -> Vertex {
        let v = Vertex(_id: nextVertexId)
        nextVertexId &+= 1
        verticesStore.updateOrAppend(v)
        // Grow matrix
        let n = verticesStore.count
        for i in 0..<matrix.count { matrix[i].append(false) }
        matrix.append(Array(repeating: false, count: n))
        return v
    }

    mutating func remove(vertex: consuming Vertex) {
        guard let idx = index(of: vertex) else { return }
        // Remove incident edges
        for e in outgoingEdges(of: vertex) { edgesStore.removeValue(forKey: e) }
        for e in incomingEdges(of: vertex) { edgesStore.removeValue(forKey: e) }
        // Remove row and column
        matrix.remove(at: idx)
        for i in 0..<matrix.count { matrix[i].remove(at: idx) }
        verticesStore.remove(vertex)
    }
}

extension AdjacencyMatrix: AdjacencyGraph {
    func adjacentVertices(of vertex: Vertex) -> OrderedSet<Vertex> {
        guard let idx = index(of: vertex) else { return [] }
        var result: OrderedSet<Vertex> = []
        // Outgoing neighbors: row scan
        for j in 0..<matrix.count {
            if matrix[idx][j] { result.updateOrAppend(verticesStore[j]) }
        }
        // Incoming neighbors: column scan
        for i in 0..<matrix.count {
            if matrix[i][idx] { result.updateOrAppend(verticesStore[i]) }
        }
        return result
    }
}

private extension AdjacencyMatrix {
    func index(of v: Vertex) -> Int? { verticesStore.firstIndex(of: v) }
}


