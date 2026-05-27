/// A unified query API for the per-vertex result of a single-source shortest-path computation.
///
/// Conforming types (e.g. ``Dijkstra/Result``, ``UniformCostSearch/Result``, ``AStar/Result``)
/// expose the same surface for reading distances and reconstructing paths, so call sites can
/// swap algorithms without changing how they consume the result.
public protocol ShortestPathResult<Vertex, Edge, Weight> {
    /// The vertex descriptor type.
    associatedtype Vertex
    /// The edge descriptor type.
    associatedtype Edge
    /// The weight type used for distances.
    associatedtype Weight

    /// The source vertex from which shortest paths were computed.
    var source: Vertex { get }

    /// The distance from ``source`` to `vertex`, or ``Cost/infinite`` if unreached.
    func distance(of vertex: Vertex) -> Cost<Weight>

    /// The edge by which `vertex` was reached on its shortest path, or `nil` if it has no
    /// predecessor (either it is the source or it has not been reached).
    func predecessorEdge(of vertex: Vertex) -> Edge?

    /// Whether a finite-distance path from ``source`` to `vertex` has been found.
    func hasPath(to vertex: Vertex) -> Bool
}

extension ShortestPathResult {
    /// The predecessor vertex of `vertex` along its shortest path, or `nil` if none.
    @inlinable
    public func predecessor<G: IncidenceGraph>(
        of vertex: Vertex,
        in graph: G
    ) -> Vertex? where G.VertexDescriptor == Vertex, G.EdgeDescriptor == Edge {
        predecessorEdge(of: vertex).flatMap(graph.source)
    }

    /// The sequence of vertex/edge pairs from ``source`` to `destination` (excluding ``source``).
    @inlinable
    public func path<G: IncidenceGraph>(
        to destination: Vertex,
        in graph: G
    ) -> [(vertex: Vertex, edge: Edge)] where G.VertexDescriptor == Vertex, G.EdgeDescriptor == Edge {
        var current = destination
        var result: [(Vertex, Edge)] = []
        while let predecessorEdge = predecessorEdge(of: current) {
            result.insert((current, predecessorEdge), at: 0)
            guard let predecessor = graph.source(of: predecessorEdge) else { break }
            current = predecessor
        }
        return result
    }

    /// All vertices on the shortest path from ``source`` to `destination`, in order.
    @inlinable
    public func vertices<G: IncidenceGraph>(
        to destination: Vertex,
        in graph: G
    ) -> [Vertex] where G.VertexDescriptor == Vertex, G.EdgeDescriptor == Edge {
        [source] + path(to: destination, in: graph).map(\.vertex)
    }

    /// All edges on the shortest path from ``source`` to `destination`, in order.
    @inlinable
    public func edges<G: IncidenceGraph>(
        to destination: Vertex,
        in graph: G
    ) -> [Edge] where G.VertexDescriptor == Vertex, G.EdgeDescriptor == Edge {
        path(to: destination, in: graph).map(\.edge)
    }
}
