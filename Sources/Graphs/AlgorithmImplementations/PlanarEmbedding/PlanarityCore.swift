/// Bridges the library's graph protocols to the integer-indexed `LeftRightPlanarity`
/// engine, and exposes the correct planarity decision that all public planarity APIs
/// delegate to.
enum PlanarityCore {
    /// An undirected, 0-indexed view of a graph: a stable vertex ordering, a
    /// vertex→index map, and a simple-graph adjacency list (self-loops and parallel
    /// edges removed, since neither affects planarity).
    struct IndexedGraph<Vertex: Hashable> {
        let vertices: [Vertex]
        let indexOf: [Vertex: Int]
        let adjacency: [[Int]]
    }

    /// Builds the undirected, deduplicated index view of a graph.
    static func indexed<Graph>(
        _ graph: Graph
    ) -> IndexedGraph<Graph.VertexDescriptor>
    where
        Graph: IncidenceGraph & VertexListGraph & EdgeListGraph,
        Graph.VertexDescriptor: Hashable
    {
        let vertices = Array(graph.vertices())
        var indexOf: [Graph.VertexDescriptor: Int] = [:]
        indexOf.reserveCapacity(vertices.count)
        for (index, vertex) in vertices.enumerated() {
            indexOf[vertex] = index
        }

        let n = vertices.count
        var adjacency = Array(repeating: [Int](), count: n)
        var seen = Set<Int>()
        for edge in graph.edges() {
            guard
                let source = graph.source(of: edge),
                let destination = graph.destination(of: edge),
                let a = indexOf[source],
                let b = indexOf[destination],
                a != b
            else { continue }
            let key = a < b ? a * n + b : b * n + a
            guard seen.insert(key).inserted else { continue }
            adjacency[a].append(b)
            adjacency[b].append(a)
        }

        return IndexedGraph(vertices: vertices, indexOf: indexOf, adjacency: adjacency)
    }

    /// Decides whether `graph` is planar using the Left–Right test.
    static func isPlanar<Graph>(_ graph: Graph) -> Bool
    where
        Graph: IncidenceGraph & VertexListGraph & EdgeListGraph,
        Graph.VertexDescriptor: Hashable
    {
        let indexed = indexed(graph)
        let engine = LeftRightPlanarity(n: indexed.vertices.count, adj: indexed.adjacency)
        return engine.isPlanar()
    }
}
