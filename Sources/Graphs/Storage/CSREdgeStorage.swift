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

    // Map vertex -> row index in CSR
    private var vertexIndex: OrderedDictionary<Vertex, Int> = [:]
    // CSR row offsets (size = vertexIndex.count + 1). flatEdgeIds[rowOffsets[i]..<rowOffsets[i+1]] are outgoing of vertex with index i
    private var rowOffsets: [Int] = [0]
    // Flat array of edge ids grouped by source vertex
    private var flatEdgeIds: [Int] = []

    // Edge endpoint lookup by edge id
    private var edgeSources: [Vertex] = []
    private var edgeDestinations: [Vertex] = []
    // Alive edges set for quick membership and iteration
    private var alive: OrderedSet<Int> = []
    // Reuse ids of removed edges
    private var freeList: [Int] = []

    // Incoming adjacency buckets for O(1) incoming queries
    private var incomingBuckets: OrderedDictionary<Vertex, OrderedSet<Int>> = [:]

    init() {}

    // MARK: - EdgeStorage

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
        guard let vIndex = vertexIndex[vertex] else { return [] }
        let start = rowOffsets[vIndex]
        let end = rowOffsets[vIndex + 1]
        var result: OrderedSet<Edge> = []
        result.reserveCapacity(end - start)
        var i = start
        while i < end {
            let id = flatEdgeIds[i]
            if alive.contains(id) { result.updateOrAppend(Edge(id: id)) }
            i &+= 1
        }
        return result
    }

    func outDegree(of vertex: Vertex) -> Int {
        guard let vIndex = vertexIndex[vertex] else { return 0 }
        return rowOffsets[vIndex + 1] - rowOffsets[vIndex]
    }

    func incomingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        if let bucket = incomingBuckets[vertex] {
            var result: OrderedSet<Edge> = []
            result.reserveCapacity(bucket.count)
            for id in bucket where alive.contains(id) { result.updateOrAppend(Edge(id: id)) }
            return result
        } else {
            return []
        }
    }

    func inDegree(of vertex: Vertex) -> Int {
        incomingBuckets[vertex]?.count ?? 0
    }

    // MARK: - Mutations

    private mutating func ensureIndex(for vertex: Vertex) -> Int {
        if let idx = vertexIndex[vertex] { return idx }
        let newIndex = vertexIndex.count
        vertexIndex[vertex] = newIndex
        rowOffsets.append(rowOffsets.last!)
        return newIndex
    }

    mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge {
        let id: Int
        if let reused = freeList.popLast() {
            id = reused
            edgeSources[id] = source
            edgeDestinations[id] = destination
        } else {
            id = edgeSources.count
            edgeSources.append(source)
            edgeDestinations.append(destination)
        }
        alive.updateOrAppend(id)

        // CSR insertion
        let sIdx = ensureIndex(for: source)
        let insertAt = rowOffsets[sIdx + 1]
        flatEdgeIds.insert(id, at: insertAt)
        // Shift subsequent row offsets
        var j = sIdx + 1
        while j < rowOffsets.count {
            rowOffsets[j] &+= 1
            j &+= 1
        }

        // Incoming bucket
        incomingBuckets[destination, default: []].updateOrAppend(id)

        return Edge(id: id)
    }

    mutating func remove(edge: Edge) {
        let id = edge.id
        guard id >= 0 && id < edgeSources.count else { return }
        if !alive.contains(id) { return }
        let source = edgeSources[id]
        let destination = edgeDestinations[id]

        // Remove from CSR segment
        if let sIdx = vertexIndex[source] {
            let start = rowOffsets[sIdx]
            let end = rowOffsets[sIdx + 1]
            if let pos = flatEdgeIds[start..<end].firstIndex(of: id) {
                flatEdgeIds.remove(at: pos)
                var j = sIdx + 1
                while j < rowOffsets.count {
                    rowOffsets[j] &-= 1
                    j &-= -1 // increment
                }
            }
        }

        // Remove from incoming bucket
        incomingBuckets[destination]?.remove(id)

        // Mark edge as free
        alive.remove(id)
        freeList.append(id)
    }
}

