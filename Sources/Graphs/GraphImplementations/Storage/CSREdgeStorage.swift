import Collections

/// A dynamic CSR-like edge storage.
///
/// Notes:
/// - Maintains CSR row offsets and a flat edge-id array for outgoing edge queries.
/// - Supports dynamic insert/remove with O(V) row-offset updates on mutation.
/// - Also maintains incoming buckets for O(1) incoming edge queries.
struct CSREdgeStorage<Vertex: Hashable>: EdgeStorage {
    struct Edge: Identifiable, Hashable {
        let id: Int
    }

    private var vertexIndex: OrderedDictionary<Vertex, Int> = [:]
    private var rowOffsets: [Int] = [0]
    private var flatEdgeIds: [Int] = []
    private var edgeSources: [Vertex] = []
    private var edgeDestinations: [Vertex] = []
    private var alive: OrderedSet<Int> = []
    private var freeList: [Int] = []
    private var incomingBuckets: OrderedDictionary<Vertex, OrderedSet<Int>> = [:]

    init() {}

    var edgeCount: Int { alive.count }

    func edges() -> OrderedSet<Edge> {
        var result: OrderedSet<Edge> = []
        result.reserveCapacity(alive.count)
        for id in alive { result.updateOrAppend(Edge(id: id)) }
        return result
    }

    func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)? {
        let id = edge.id
        guard id >= 0 && id < edgeSources.count else { return nil }
        if !alive.contains(id) { return nil }
        return (edgeSources[id], edgeDestinations[id])
    }

    func outgoingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        guard let vertexIndex = vertexIndex[vertex] else { return [] }
        let startIndex = rowOffsets[vertexIndex]
        let endIndex = rowOffsets[vertexIndex + 1]
        var result: OrderedSet<Edge> = []
        result.reserveCapacity(endIndex - startIndex)
        var currentIndex = startIndex
        while currentIndex < endIndex {
            let edgeId = flatEdgeIds[currentIndex]
            if alive.contains(edgeId) { result.updateOrAppend(Edge(id: edgeId)) }
            currentIndex &+= 1
        }
        return result
    }

    func outDegree(of vertex: Vertex) -> Int {
        guard let vertexIndex = vertexIndex[vertex] else { return 0 }
        return rowOffsets[vertexIndex + 1] - rowOffsets[vertexIndex]
    }

    func incomingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        guard let bucket = incomingBuckets[vertex] else { return [] }
        var result: OrderedSet<Edge> = []
        result.reserveCapacity(bucket.count)
        for edgeId in bucket where alive.contains(edgeId) { 
            result.updateOrAppend(Edge(id: edgeId)) 
        }
        return result
    }

    func inDegree(of vertex: Vertex) -> Int {
        incomingBuckets[vertex]?.count ?? 0
    }

    private mutating func ensureIndex(for vertex: Vertex) -> Int {
        if let existingIndex = vertexIndex[vertex] { return existingIndex }
        let newIndex = vertexIndex.count
        vertexIndex[vertex] = newIndex
        rowOffsets.append(rowOffsets.last ?? 0)
        return newIndex
    }

    mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge {
        let edgeId: Int
        if let reusedId = freeList.popLast() {
            edgeId = reusedId
            edgeSources[edgeId] = source
            edgeDestinations[edgeId] = destination
        } else {
            edgeId = edgeSources.count
            edgeSources.append(source)
            edgeDestinations.append(destination)
        }
        alive.updateOrAppend(edgeId)

        let sourceIndex = ensureIndex(for: source)
        let insertPosition = rowOffsets[sourceIndex + 1]
        flatEdgeIds.insert(edgeId, at: insertPosition)
        
        var currentIndex = sourceIndex + 1
        while currentIndex < rowOffsets.count {
            rowOffsets[currentIndex] &+= 1
            currentIndex &+= 1
        }

        incomingBuckets[destination, default: []].updateOrAppend(edgeId)

        return Edge(id: edgeId)
    }

    mutating func remove(edge: Edge) {
        let edgeId = edge.id
        guard edgeId >= 0 && edgeId < edgeSources.count else { return }
        if !alive.contains(edgeId) { return }
        let source = edgeSources[edgeId]
        let destination = edgeDestinations[edgeId]

        if let sourceIndex = vertexIndex[source] {
            let startIndex = rowOffsets[sourceIndex]
            let endIndex = rowOffsets[sourceIndex + 1]
            if let position = flatEdgeIds[startIndex..<endIndex].firstIndex(of: edgeId) {
                flatEdgeIds.remove(at: position)
                var currentIndex = sourceIndex + 1
                while currentIndex < rowOffsets.count {
                    rowOffsets[currentIndex] &-= 1
                    currentIndex &+= 1
                }
            }
        }

        incomingBuckets[destination]?.remove(edgeId)
        alive.remove(edgeId)
        freeList.append(edgeId)
    }
}

