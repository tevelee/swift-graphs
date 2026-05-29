#if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
@testable import Graphs
import Testing

struct EdgeStorageBackendTests {
    @Test func cooAdjacencyList_basic() {
        var g = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges())

        let u = g.addVertex()
        let v = g.addVertex()
        let w = g.addVertex()

        let uv = g.addEdge(from: u, to: v)!
        let uw = g.addEdge(from: u, to: w)!

        #expect(g.edgeCount == 2)
        #expect(Array(g.outgoingEdges(of: u)) == [uv, uw])
        #expect(Array(g.incomingEdges(of: v)) == [uv])
        #expect(Array(g.incomingEdges(of: w)) == [uw])
    }

    @Test func csrAdjacencyList_basic() {
        var g = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges())

        let a = g.addVertex()
        let b = g.addVertex()
        let c = g.addVertex()

        g.addEdge(from: a, to: b)
        g.addEdge(from: a, to: c)
        g.addEdge(from: c, to: b)

        #expect(g.vertexCount == 3)
        #expect(g.edgeCount == 3)

        // Degrees and incidence
        #expect(g.outDegree(of: a) == 2)
        #expect(g.inDegree(of: b) == 2)
    }

    // MARK: - Edge removal

    @Test func cooAdjacencyList_edgeRemoval() {
        var g = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges())
        let u = g.addVertex()
        let v = g.addVertex()
        let w = g.addVertex()
        let uv = g.addEdge(from: u, to: v)!
        let uw = g.addEdge(from: u, to: w)!

        #expect(g.edgeCount == 2)
        g.remove(edge: uv)
        #expect(g.edgeCount == 1)
        #expect(Array(g.outgoingEdges(of: u)) == [uw])
        #expect(Array(g.incomingEdges(of: v)).isEmpty, "v has no incoming edges after removal")
    }

    @Test func csrAdjacencyList_edgeRemoval() {
        var g = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges())
        let a = g.addVertex()
        let b = g.addVertex()
        let c = g.addVertex()
        let ab = g.addEdge(from: a, to: b)!
        _ = g.addEdge(from: a, to: c)!

        g.remove(edge: ab)
        #expect(g.edgeCount == 1)
        // After removal, edges() iterates only alive edges
        let remaining = Array(g.edges())
        #expect(remaining.count == 1)
        #expect(g.outDegree(of: a) == 1)
        #expect(g.inDegree(of: b) == 0, "b has no incoming edges after the only edge to it was removed")
    }

    // MARK: - BFS on COO/CSR backends

    @Test func cooAdjacencyList_bfsReachesAllVertices() {
        var g = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges())
        let a = g.addVertex(); let b = g.addVertex(); let c = g.addVertex()
        g.addEdge(from: a, to: b)
        g.addEdge(from: b, to: c)

        let visited = BreadthFirstSearch(on: g, from: a).map { $0.currentVertex }
        #expect(visited == [a, b, c], "COO-backed BFS visits chain vertices in order")
    }

    @Test func csrAdjacencyList_bfsReachesAllVertices() {
        var g = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges())
        let a = g.addVertex(); let b = g.addVertex(); let c = g.addVertex()
        g.addEdge(from: a, to: b)
        g.addEdge(from: b, to: c)

        let visited = BreadthFirstSearch(on: g, from: a).map { $0.currentVertex }
        #expect(visited == [a, b, c], "CSR-backed BFS visits chain vertices in order")
    }

    // MARK: - Dijkstra on COO/CSR backends

    @Test func cooAdjacencyList_dijkstraFindsShortestPath() {
        var g = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges())
        let a = g.addVertex(); let b = g.addVertex(); let c = g.addVertex()
        g.addEdge(from: a, to: b) { $0.weight = 1.0 }
        g.addEdge(from: b, to: c) { $0.weight = 1.0 }
        g.addEdge(from: a, to: c) { $0.weight = 10.0 }

        // Shortest path from a to c should go through b (total cost 2, not direct cost 10)
        let path = g.shortestPath(from: a, to: c, using: .dijkstra(weight: .property(\.weight)))
        #expect(path != nil, "COO-backed Dijkstra must find a path from a to c")
        #expect(path?.vertices.count == 3, "Optimal path a→b→c visits 3 vertices")
        #expect(path?.vertices == [a, b, c], "COO-backed Dijkstra prefers a→b→c (cost 2) over a→c (cost 10)")
    }

    @Test func csrAdjacencyList_dijkstraFindsShortestPath() {
        var g = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges())
        let a = g.addVertex(); let b = g.addVertex(); let c = g.addVertex()
        g.addEdge(from: a, to: b) { $0.weight = 1.0 }
        g.addEdge(from: b, to: c) { $0.weight = 1.0 }
        g.addEdge(from: a, to: c) { $0.weight = 10.0 }

        let path = g.shortestPath(from: a, to: c, using: .dijkstra(weight: .property(\.weight)))
        #expect(path != nil, "CSR-backed Dijkstra must find a path from a to c")
        #expect(path?.vertices.count == 3, "Optimal path a→b→c visits 3 vertices")
        #expect(path?.vertices == [a, b, c], "CSR-backed Dijkstra prefers a→b→c (cost 2) over a→c (cost 10)")
    }

    // MARK: - Full edge enumeration

    @Test func cooAdjacencyList_edgesEnumeration() {
        var g = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges())
        let a = g.addVertex(); let b = g.addVertex(); let c = g.addVertex()
        g.addEdge(from: a, to: b)
        g.addEdge(from: b, to: c)
        g.addEdge(from: a, to: c)

        let edges = Array(g.edges())
        #expect(edges.count == 3, "COO edges() enumerates all 3 edges")
        // endpoints(of:) must be correct for each edge
        for edge in edges {
            let src = g.source(of: edge)
            let dst = g.destination(of: edge)
            #expect(src != nil && dst != nil, "each edge has valid endpoints")
        }
    }

    @Test func csrAdjacencyList_edgesEnumeration() {
        var g = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges())
        let a = g.addVertex(); let b = g.addVertex(); let c = g.addVertex()
        g.addEdge(from: a, to: b)
        g.addEdge(from: b, to: c)
        g.addEdge(from: a, to: c)

        let edges = Array(g.edges())
        #expect(edges.count == 3, "CSR edges() enumerates all 3 edges")
        for edge in edges {
            #expect(g.source(of: edge) != nil)
            #expect(g.destination(of: edge) != nil)
        }
    }
}
#endif
