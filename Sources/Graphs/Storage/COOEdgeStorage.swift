import Collections

struct COOEdgeStorage<Vertex: Hashable>: EdgeStorage {
    struct Edge: Identifiable, Hashable {
        let id: Int
    }

    private var sources: [Vertex] = []
    private var destinations: [Vertex] = []
    private var freeList: [Int] = []

    var edgeCount: Int {
        sources.count - freeList.count
    }

    func edges() -> OrderedSet<Edge> {
        var result: OrderedSet<Edge> = []
        result.reserveCapacity(sources.count)
        for raw in 0..<sources.count {
            if !freeList.contains(raw) {
                result.updateOrAppend(Edge(id: raw))
            }
        }
        return result
    }

    func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)? {
        let idx = edge.id
        guard idx >= 0 && idx < sources.count else { return nil }
        if freeList.contains(idx) { return nil }
        return (sources[idx], destinations[idx])
    }

    func outgoingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        var result: OrderedSet<Edge> = []
        result.reserveCapacity(8)
        if sources.isEmpty { return result }
        for i in 0..<sources.count {
            if freeList.contains(i) { continue }
            if sources[i] == vertex { result.updateOrAppend(Edge(id: i)) }
        }
        return result
    }

    func outDegree(of vertex: Vertex) -> Int {
        outgoingEdges(of: vertex).count
    }

    func incomingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        var result: OrderedSet<Edge> = []
        result.reserveCapacity(8)
        if destinations.isEmpty { return result }
        for i in 0..<destinations.count {
            if freeList.contains(i) { continue }
            if destinations[i] == vertex { result.updateOrAppend(Edge(id: i)) }
        }
        return result
    }

    func inDegree(of vertex: Vertex) -> Int {
        incomingEdges(of: vertex).count
    }

    mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge {
        if let reused = freeList.popLast() {
            sources[reused] = source
            destinations[reused] = destination
            let edge = Edge(id: reused)
            return edge
        } else {
            let id = sources.count
            sources.append(source)
            destinations.append(destination)
            let edge = Edge(id: id)
            return edge
        }
    }

    mutating func remove(edge: Edge) {
        guard endpoints(of: edge) != nil else { return }
        freeList.append(edge.id)
    }
}


