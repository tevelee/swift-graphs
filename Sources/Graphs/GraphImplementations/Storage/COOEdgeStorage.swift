#if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
import Collections

/// A coordinate (COO) format edge storage implementation.
///
/// COOEdgeStorage stores edges as coordinate pairs (source, destination) in parallel arrays.
/// This format is efficient for sparse graphs and provides good performance for edge insertion
/// and removal operations.
public struct COOEdgeStorage<Vertex: Hashable>: EdgeStorage {
    /// An edge descriptor for COO format edges.
    public struct Edge: Identifiable, Hashable {
        public let id: Int
        
        @inlinable
        public init(id: Int) {
            self.id = id
        }
    }

    @usableFromInline
    var sources: [Vertex] = []
    @usableFromInline
    var destinations: [Vertex] = []
    // Use a Set for O(1) tombstone checks
    @usableFromInline
    var tombstones: Set<Int> = []

    @inlinable
    public var edgeCount: Int {
        sources.count - tombstones.count
    }

    @inlinable
    public func edges() -> OrderedSet<Edge> {
        var result: OrderedSet<Edge> = []
        result.reserveCapacity(sources.count)
        for index in 0 ..< sources.count {
            if !tombstones.contains(index) {
                result.updateOrAppend(Edge(id: index))
            }
        }
        return result
    }

    @inlinable
    public func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)? {
        let index = edge.id
        guard index >= 0 && index < sources.count else { return nil }
        if tombstones.contains(index) { return nil }
        return (sources[index], destinations[index])
    }

    @inlinable
    public func outgoingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        var result: OrderedSet<Edge> = []
        if sources.isEmpty { return result }
        for index in 0 ..< sources.count {
            if tombstones.contains(index) { continue }
            if sources[index] == vertex { result.updateOrAppend(Edge(id: index)) }
        }
        return result
    }

    @inlinable
    public func outDegree(of vertex: Vertex) -> Int {
        outgoingEdges(of: vertex).count
    }

    @inlinable
    public func incomingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        var result: OrderedSet<Edge> = []
        if destinations.isEmpty { return result }
        for index in 0 ..< destinations.count {
            if tombstones.contains(index) { continue }
            if destinations[index] == vertex { result.updateOrAppend(Edge(id: index)) }
        }
        return result
    }

    @inlinable
    public func inDegree(of vertex: Vertex) -> Int {
        incomingEdges(of: vertex).count
    }

    @inlinable
    public mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge {
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

    @inlinable
    public mutating func remove(edge: Edge) {
        guard endpoints(of: edge) != nil else { return }
        tombstones.insert(edge.id)
    }
}
#endif
