import Collections

struct COOEdgeStorage<Vertex: Hashable>: EdgeStorage {
    struct Edge: Identifiable, Hashable {
        let id: Int
    }

    private var sources: [Vertex] = []
    private var destinations: [Vertex] = []
    // Use a Set for O(1) tombstone checks
    private var tombstones: Set<Int> = []

    var edgeCount: Int {
        sources.count - tombstones.count
    }

    func edges() -> OrderedSet<Edge> {
        var result: OrderedSet<Edge> = []
        result.reserveCapacity(sources.count)
        for raw in 0..<sources.count {
            if !tombstones.contains(raw) {
                result.updateOrAppend(Edge(id: raw))
            }
        }
        return result
    }

    func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)? {
        let idx = edge.id
        guard idx >= 0 && idx < sources.count else { return nil }
        if tombstones.contains(idx) { return nil }
        return (sources[idx], destinations[idx])
    }

    func outgoingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        var result: OrderedSet<Edge> = []
        result.reserveCapacity(8)
        if sources.isEmpty { return result }
        for i in 0..<sources.count {
            if tombstones.contains(i) { continue }
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
            if tombstones.contains(i) { continue }
            if destinations[i] == vertex { result.updateOrAppend(Edge(id: i)) }
        }
        return result
    }

    func inDegree(of vertex: Vertex) -> Int {
        incomingEdges(of: vertex).count
    }

    mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge {
        // Try to reuse a tombstoned slot if any
        if let reused = tombstones.first {
            tombstones.remove(reused)
            sources[reused] = source
            destinations[reused] = destination
            return Edge(id: reused)
        }
        let id = sources.count
        sources.append(source)
        destinations.append(destination)
        return Edge(id: id)
    }

    mutating func remove(edge: Edge) {
        guard endpoints(of: edge) != nil else { return }
        tombstones.insert(edge.id)
    }
}


