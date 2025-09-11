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
        for index in 0 ..< sources.count {
            if !tombstones.contains(index) {
                result.updateOrAppend(Edge(id: index))
            }
        }
        return result
    }

    func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)? {
        let index = edge.id
        guard index >= 0 && index < sources.count else { return nil }
        if tombstones.contains(index) { return nil }
        return (sources[index], destinations[index])
    }

    func outgoingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        var result: OrderedSet<Edge> = []
        if sources.isEmpty { return result }
        for index in 0 ..< sources.count {
            if tombstones.contains(index) { continue }
            if sources[index] == vertex { result.updateOrAppend(Edge(id: index)) }
        }
        return result
    }

    func outDegree(of vertex: Vertex) -> Int {
        outgoingEdges(of: vertex).count
    }

    func incomingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        var result: OrderedSet<Edge> = []
        if destinations.isEmpty { return result }
        for index in 0 ..< destinations.count {
            if tombstones.contains(index) { continue }
            if destinations[index] == vertex { result.updateOrAppend(Edge(id: index)) }
        }
        return result
    }

    func inDegree(of vertex: Vertex) -> Int {
        incomingEdges(of: vertex).count
    }

    mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge {
        if let reusedIndex = tombstones.first {
            tombstones.remove(reusedIndex)
            sources[reusedIndex] = source
            destinations[reusedIndex] = destination
            return Edge(id: reusedIndex)
        }
        let newIndex = sources.count
        sources.append(source)
        destinations.append(destination)
        return Edge(id: newIndex)
    }

    mutating func remove(edge: Edge) {
        guard endpoints(of: edge) != nil else { return }
        tombstones.insert(edge.id)
    }
}


