#if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
import Collections

/// A compressed sparse row (CSR) format edge storage implementation.
///
/// CSREdgeStorage provides efficient storage for sparse graphs using the CSR format,
/// which is optimized for graph algorithms that need to iterate over outgoing edges
/// of vertices. This format provides excellent cache locality for traversal operations.
public struct CSREdgeStorage<Vertex: Hashable>: EdgeStorage {
    /// An edge descriptor for CSR format edges.
    public struct Edge: Identifiable, Hashable {
        public let id: Int
        
        @inlinable
        public init(id: Int) {
            self.id = id
        }
    }

    @usableFromInline
    var vertexIndex: OrderedDictionary<Vertex, Int> = [:]
    @usableFromInline
    var rowOffsets: [Int] = [0]
    @usableFromInline
    var flatEdgeIds: [Int] = []
    @usableFromInline
    var edgeSources: [Vertex] = []
    @usableFromInline
    var edgeDestinations: [Vertex] = []
    @usableFromInline
    var alive: OrderedSet<Int> = []
    @usableFromInline
    var freeList: [Int] = []
    @usableFromInline
    var incomingBuckets: OrderedDictionary<Vertex, OrderedSet<Int>> = [:]

    @inlinable
    public var edgeCount: Int { alive.count }

    @inlinable
    public func edges() -> OrderedSet<Edge> {
        var result: OrderedSet<Edge> = []
        result.reserveCapacity(alive.count)
        for id in alive { result.updateOrAppend(Edge(id: id)) }
        return result
    }

    @inlinable
    public func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)? {
        let id = edge.id
        guard id >= 0 && id < edgeSources.count else { return nil }
        if !alive.contains(id) { return nil }
        return (edgeSources[id], edgeDestinations[id])
    }

    @inlinable
    public func outgoingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
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

    @inlinable
    public func outDegree(of vertex: Vertex) -> Int {
        guard let vertexIndex = vertexIndex[vertex] else { return 0 }
        return rowOffsets[vertexIndex + 1] - rowOffsets[vertexIndex]
    }

    @inlinable
    public func incomingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        guard let bucket = incomingBuckets[vertex] else { return [] }
        var result: OrderedSet<Edge> = []
        result.reserveCapacity(bucket.count)
        for edgeId in bucket where alive.contains(edgeId) { 
            result.updateOrAppend(Edge(id: edgeId)) 
        }
        return result
    }

    @inlinable
    public func inDegree(of vertex: Vertex) -> Int {
        incomingBuckets[vertex]?.count ?? 0
    }

    @usableFromInline
    mutating func ensureIndex(for vertex: Vertex) -> Int {
        if let existingIndex = vertexIndex[vertex] { return existingIndex }
        let newIndex = vertexIndex.count
        vertexIndex[vertex] = newIndex
        rowOffsets.append(rowOffsets.last ?? 0)
        return newIndex
    }

    @inlinable
    public mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge {
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

    @inlinable
    public mutating func remove(edge: Edge) {
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
#endif
